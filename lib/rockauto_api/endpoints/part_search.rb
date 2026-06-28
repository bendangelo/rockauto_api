# frozen_string_literal: true

module RockautoApi
  module Endpoints
    module PartSearch
      def get_manufacturers
        cache.fetch("rockauto:manufacturers", ttl: 86400) do
          html = get("/en/partsearch/")
          opts = Parsers::HtmlHelpers.select_options(html, "manufacturer_partsearch_007")
          manufacturers = opts.map { |o| Models::PartSearchOption.new(value: o[:value], text: o[:text]) }
          Models::ManufacturerOptions.new(
            manufacturers: manufacturers,
            count: manufacturers.size
          )
        end
      end

      def get_part_groups
        cache.fetch("rockauto:part_groups", ttl: 86400) do
          html = get("/en/partsearch/")
          opts = Parsers::HtmlHelpers.select_options(html, "partgroup_partsearch_007")
          groups = opts.map { |o| Models::PartSearchOption.new(value: o[:value], text: o[:text]) }
          Models::PartGroupOptions.new(
            part_groups: groups,
            count: groups.size
          )
        end
      end

      def get_part_types
        cache.fetch("rockauto:part_types", ttl: 86400) do
          html = get("/en/partsearch/")
          opts = Parsers::HtmlHelpers.select_options(html, "parttype_partsearch_007")
          types = opts.map { |o| Models::PartSearchOption.new(value: o[:value], text: o[:text]) }
          Models::PartTypeOptions.new(
            part_types: types,
            count: types.size
          )
        end
      end

      def search_parts_by_number(part_number, manufacturer: nil, part_group: nil, part_type: nil, part_name: nil, include_fitments: false)
        man_value = ""
        group_value = ""
        type_value = ""

        if manufacturer
          mans = get_manufacturers
          match = mans.lookup(manufacturer)
          man_value = match&.value || ""
        end

        if part_group
          groups = get_part_groups
          match = groups.lookup(part_group)
          group_value = match&.value || ""
        end

        if part_type
          types = get_part_types
          match = types.lookup(part_type)
          type_value = match&.value || ""
        end

        init_session!

        page_resp = @conn.get("/en/partsearch/")
        nck = Parsers::HtmlHelpers.extract_csrf_token(page_resp.body)

        form_data = {
          "_nck" => nck || "",
          "_jnck" => @jnck_token || "",
          "dopartsearch" => "1",
          "partsearch[partnum][partsearch_007]" => part_number,
          "partsearch[manufacturer][partsearch_007]" => man_value,
          "partsearch[partgroup][partsearch_007]" => group_value,
          "partsearch[parttype][partsearch_007]" => type_value,
          "partsearch[partname][partsearch_007]" => part_name || "",
          "partsearch[do][partsearch_007]" => "Search",
          "func" => "sendparttabsearch",
          "payload" => "{}",
          "api_json_request" => "1",
          "sctchecked" => "1",
          "scbeenloaded" => "false",
          "curCartGroupID" => ""
        }

        resp = Faraday.new(url: "https://www.rockauto.com") do |f|
          f.request :url_encoded
          f.use :cookie_jar
          f.adapter Faraday.default_adapter
          f.options.timeout = RockautoApi.configuration&.request_timeout || 30
          f.headers["X-Requested-With"] = "XMLHttpRequest"
          f.headers["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8"
          f.headers["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1"
          f.headers["Referer"] = "https://www.rockauto.com/en/partsearch/"
          @conn.headers["Cookie"].to_s.split(";").each do |cookie|
            name, val = cookie.strip.split("=", 2)
            f.headers["Cookie"] = "#{f.headers['Cookie']}; #{name}=#{val}" if name && val
          end
        end.post("catalog/catalogapi.php", form_data)

        response = JSON.parse(resp.body)

        parts = parse_part_search_json(response)
        parts = parts.map do |p|
          attrs = p.to_h
          if include_fitments && attrs[:listing_data]
            attrs[:buyers_guide] = get_fitment_for_part(attrs[:listing_data])
          end
          Models::PartInfo.new(**attrs)
        end

        Models::PartSearchResult.new(
          parts: parts,
          count: parts.size,
          search_term: part_number,
          manufacturer: manufacturer || "All",
          part_group: part_group || "All"
        )
      rescue Faraday::Error => e
        raise NetworkError, "Part search failed: #{e.message}"
      end

      def what_is_part_called(search_query)
        html = post("/en/partsearch/", {
          "topsearchinput[input]" => search_query,
          "topsearchinput[submit]" => "Search"
        })
        doc = Nokogiri::HTML(html)
        results = parse_what_is_called_results(doc)

        Models::WhatIsPartCalledResults.new(
          results: results,
          count: results.size,
          search_term: search_query
        )
      end

      private

      def parse_part_search_results(doc)
        doc.css("table tr").map { |row|
          cells = row.css("td")
          next nil if cells.size < 3

          part = Parsers::PartExtractor.extract_from_row(row)
          next nil unless part

          listing_data = extract_listing_data_from_row(row)

          attrs = part.to_h
          attrs[:listing_data] = listing_data if listing_data
          Models::PartInfo.new(**attrs)
        }.compact
      end

      def extract_listing_data_from_row(row)
        data = {}

        row.css("[data-groupindex], [data-carcode], [data-parttype], [data-partkey], [data-partnumber], [data-catalogname], [data-optkey]").each do |el|
          data["groupindex"] = el["data-groupindex"] if el["data-groupindex"]
          data["car"] = { "carcode" => el["data-carcode"], "parttype" => el["data-parttype"], "partkey" => el["data-partkey"] }
          data["supplemental"] = { "partnumber" => el["data-partnumber"], "catalogname" => el["data-catalogname"] }
          data["optkey"] = el["data-optkey"] if el["data-optkey"]
        end

        row.css("a").each do |a|
          onclick = a["onclick"]
          next unless onclick
          match = onclick.match(/getbuyersguide\('([^']+)'/)
          data["buyersguide_key"] = match[1] if match
        end

        data.empty? ? nil : data
      end

      def parse_part_search_json(response)
        html = response["searchnoderesults"]
        return [] unless html && !html.empty?

        doc = Nokogiri::HTML(html)
        parse_part_search_listings(doc)
      end

      def parse_part_search_listings(doc)
        doc.css(".listing-container-c").map { |container|
          begin
            next nil if container.at_css(".listing-final-partnumber").nil?

            part_number = container.at_css(".listing-final-partnumber")&.text&.strip || "Unknown"
            brand = container.at_css(".listing-final-manufacturer")&.text&.strip
            price_el = container.at_css(".listing-price")
            price = price_el&.text&.strip
            image_elem = container.at_css("img.listing-inline-image") || container.at_css("img")
            image_url = Parsers::HtmlHelpers.make_absolute_url(image_elem["src"]) if image_elem&.attr("src")
            info_link = container.at_css("a[href*='moreinfo']")
            info_url = Parsers::HtmlHelpers.make_absolute_url(info_link["href"]) if info_link&.attr("href")
            name_text = container.at_css(".listing-text-row b")&.text&.strip
            name = name_text || "#{brand} #{part_number}"
            category_elem = container.at_css(".listing-footnote-text")
            category = category_elem&.text&.strip

            supplement_input = container.at_css("input[name='listing_data_supplemental'], input[id^='listing_data_supplemental']")
            essential_input = container.at_css("input[name^='listing_data_essential'], input[id^='listing_data_essential']")
            listing_data = nil
            if supplement_input || essential_input
              listing_data = {}
              if essential_input
                ess = JSON.parse(essential_input["value"] || "{}") rescue {}
                listing_data["groupindex"] = ess["groupindex"].to_s if ess["groupindex"]
                listing_data["car"] = { "carcode" => ess["carcode"], "parttype" => ess["parttype"], "partkey" => ess["partkey"] }
              end
              if supplement_input
                supp = JSON.parse(supplement_input["value"] || "{}") rescue {}
                listing_data["supplemental"] = { "partnumber" => supp["partnumber"], "catalogname" => supp["catalogname"] }
              end
            end

            Models::PartInfo.new(
              name: name,
              part_number: part_number,
              brand: brand,
              price: price,
              url: nil,
              image_url: image_url,
              info_url: info_url,
              category: category,
              listing_data: listing_data
            )
          rescue StandardError
            nil
          end
        }.compact
      end

      def parse_what_is_called_results(doc)
        doc.css("a").map { |a|
          text = a.text.strip
          next nil if text.empty?
          path_parts = text.split(">").map(&:strip)
          main_category = path_parts[0]
          subcategory = path_parts[1]
          Models::WhatIsPartCalledResult.new(
            main_category: main_category || "",
            subcategory: subcategory || "",
            full_path: text
          )
        }.compact
      end
    end
  end
end
