# frozen_string_literal: true

module RockautoApi
  module Parsers
    module HtmlHelpers
      BASE_URL = "https://www.rockauto.com"

      module_function

      def select_options(html_or_doc, select_id_or_css)
        doc = html_or_doc.is_a?(Nokogiri::HTML::Document) ? html_or_doc : Nokogiri::HTML(html_or_doc)
        select = doc.at_css("select##{select_id_or_css}") || doc.at_css(select_id_or_css)
        return [] unless select

        select.css("option").map { |opt|
          value = opt["value"]
          text = opt.text.strip
          next nil if value.nil? || value.empty? || text.empty?
          { value: value, text: text }
        }.compact
      end

      def extract_csrf_token(html_or_doc, name = "_nck")
        doc = html_or_doc.is_a?(Nokogiri::HTML::Document) ? html_or_doc : Nokogiri::HTML(html_or_doc)
        input = doc.at_css("input[name='#{name}']")
        input&.attr("value")
      end

      def extract_javascript_variable(html, var_name)
        html.match(/window\.#{Regexp.escape(var_name)}\s*=\s*"([^"]+)"/)&.captures&.first
      end

      def make_absolute_url(href)
        return nil if href.nil? || href.empty?
        return href if href.start_with?("http")
        href.start_with?("/") ? "#{BASE_URL}#{href}" : "#{BASE_URL}/#{href}"
      end

      def table_rows(html_or_doc, min_cells: 2)
        doc = html_or_doc.is_a?(Nokogiri::HTML::Document) ? html_or_doc : Nokogiri::HTML(html_or_doc)
        doc.css("table tr").select { |row| row.css("td").size >= min_cells }.map { |row|
          row.css("td, th").map { |cell| cell.text.strip }
        }
      end

      def find_links(html_or_doc, pattern = nil)
        doc = html_or_doc.is_a?(Nokogiri::HTML::Document) ? html_or_doc : Nokogiri::HTML(html_or_doc)
        links = doc.css("a")
        if pattern
          links = links.select { |a| a.text.strip.match?(pattern) }
        end
        links.map { |a| { text: a.text.strip, href: make_absolute_url(a["href"]) } }
      end
    end
  end
end
