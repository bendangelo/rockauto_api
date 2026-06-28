# frozen_string_literal: true

module RockautoApi
  module Endpoints
    module Tools
      def get_tool_categories(path = "/en/tools/")
        html = get(path)
        doc = Nokogiri::HTML(html)

        categories = doc.css("a").map { |a|
          text = a.text.strip
          href = a["href"]
          next nil if text.empty? || href.nil? || !href.include?("tools")
          Models::ToolCategory.new(
            name: text,
            group_name: text,
            href: Parsers::HtmlHelpers.make_absolute_url(href),
            level: path.scan("/").size - 1
          )
        }.compact

        Models::ToolCategories.new(
          categories: categories,
          count: categories.size,
          level: path.scan("/").size - 1,
          parent_path: path
        )
      end

      def get_tools_by_category(category_path)
        html = get(category_path)
        doc = Nokogiri::HTML(html)
        tools = parse_tools_from_table(doc)
        category_name = category_path.split("/").last

        Models::ToolsResult.new(
          tools: tools,
          count: tools.size,
          category: category_name,
          category_path: category_path
        )
      end

      private

      def parse_tools_from_table(doc)
        doc.css("table tr").map { |row|
          cells = row.css("td")
          next nil if cells.size < 3

          texts = cells.map { |c| c.text.strip }

          link = row.at_css("a")
          img = row.at_css("img")

          Models::ToolInfo.new(
            name: texts[1] || texts.first || "",
            part_number: texts[0] || "",
            brand: texts[2],
            description: texts[3],
            url: link ? Parsers::HtmlHelpers.make_absolute_url(link["href"]) : nil,
            image_url: img ? Parsers::HtmlHelpers.make_absolute_url(img["src"]) : nil,
            info_url: nil,
            video_url: nil,
            specifications: nil,
            category: nil,
            features: nil,
            warranty_info: nil
          )
        }.compact
      end
    end
  end
end
