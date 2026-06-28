# frozen_string_literal: true

module RockautoApi
  module Endpoints
    module PartCategories
      def get_part_categories(make, year, model, carcode)
        payload = {
          "jsn" => {
            "make" => make,
            "year" => year.to_s,
            "model" => model,
            "carcode" => carcode,
            "nodetype" => "model",
            "loaded" => false,
            "expand_after_load" => true,
            "fetching" => true,
            "max_group_index" => 0,
            "mkt_US" => true,
            "mkt_CA" => false,
            "mkt_MX" => false
          }
        }

        response = call_catalog_api("navnode_fetch", payload)
        html = response.dig("html_fill_sections", "navchildren[]") || ""

        categories = parse_categories_from_html(html)

        Models::VehiclePartCategories.new(
          make: make,
          year: year,
          model: model,
          carcode: carcode,
          categories: categories,
          count: categories.size
        )
      end

      def get_parts_by_category(make, year, model, carcode, category_group_name)
        categories_result = get_part_categories(make, year, model, carcode)
        category = categories_result.categories.find { |c| c.group_name == category_group_name }

        return Models::VehiclePartsResult.new(
          make: make, year: year, model: model, carcode: carcode,
          category: category_group_name, parts: [], count: 0
        ) unless category&.href

        html = get(category.href)
        doc = Nokogiri::HTML(html)
        parts = parse_parts_from_table(doc)

        Models::VehiclePartsResult.new(
          make: make, year: year, model: model, carcode: carcode,
          category: category_group_name, parts: parts, count: parts.size
        )
      end

      private

      def parse_categories_from_html(html)
        doc = Nokogiri::HTML(html)
        doc.css("a").map { |a|
          text = a.text.strip
          href = a["href"]
          next nil if text.empty? || href.nil?
          Models::PartCategory.new(
            name: text,
            group_name: text,
            href: Parsers::HtmlHelpers.make_absolute_url(href)
          )
        }.compact
      end

      def parse_parts_from_table(doc)
        doc.css("table tr").map { |row|
          cells = row.css("td")
          next nil if cells.size < 3
          Parsers::PartExtractor.extract_from_row(row)
        }.compact
      end
    end
  end
end
