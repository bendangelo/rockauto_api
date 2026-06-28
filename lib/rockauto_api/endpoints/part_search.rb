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

        form_data = {
          "dopartsearch" => "1",
          "partsearch[partnum][partsearch_007]" => part_number,
          "partsearch[manufacturer][partsearch_007]" => man_value,
          "partsearch[partgroup][partsearch_007]" => group_value,
          "partsearch[parttype][partsearch_007]" => type_value,
          "partsearch[partname][partsearch_007]" => part_name || "",
          "partsearch[do][partsearch_007]" => "Search"
        }

        html = post_with_csrf("/en/partsearch/", form_data)
        doc = Nokogiri::HTML(html)

        parts = parse_part_search_results(doc)
        parts = parts.map do |p|
          attrs = p.to_h
          if include_fitments && attrs[:listing_data]
            fitment_result = get_fitment_for_part(attrs[:listing_data])
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
