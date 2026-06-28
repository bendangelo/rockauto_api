# frozen_string_literal: true

module RockautoApi
  module Parsers
    class PartExtractor
      KNOWN_BRANDS = %w[
        HONDA TOYOTA FORD CHEVROLET DODGE NISSAN BMW MERCEDES VOLKSWAGEN
        SUBARU MAZDA HYUNDAI KIA AUDI LEXUS JEEP GMC RAM CHRYSLER
        BOSCH DENSO NGK ACDELCO MOTORCRAFT DELPHI WALKER MONROE
        GATES DAYCO CONTINENTAL TIMKEN SKF FEL-PRO MAHLE VICTOR
        REINZ MOOG DORMAN CARDONE STANDARD BECK/ARNLEY MEVOTECH
      ].freeze

      PART_NUMBER_REGEX = /[A-Z0-9]{6,}/
      PRICE_REGEX = /\$[\d,.]+/

      def self.extract_from_row(row_node)
        cells = row_node.css("td")
        return nil if cells.empty?

        texts = cells.map { |c| c.text.strip }.reject(&:empty?)

        price = texts.find { |t| t.match?(PRICE_REGEX) }
        part_number = texts.find { |t| t.match?(PART_NUMBER_REGEX) && !t.match?(PRICE_REGEX) }

        brand = nil
        KNOWN_BRANDS.each do |b|
          if texts.any? { |t| t.upcase.include?(b) }
            brand = b
            break
          end
        end

        name_candidates = texts.reject { |t|
          t == price || t == part_number || (brand && t.upcase.include?(brand))
        }
        name = name_candidates.max_by(&:length) || texts.first || "Unknown"

        links = row_node.css("a")
        url = nil
        image_url = nil
        info_url = nil

        links.each do |link|
          href = link["href"]
          next unless href
          if href.include?("moreinfo")
            info_url = Parsers::HtmlHelpers.make_absolute_url(href)
          elsif href.include?("catalog") && !href.include?("moreinfo")
            url = Parsers::HtmlHelpers.make_absolute_url(href)
          end
        end

        img = row_node.at_css("img")
        image_url = Parsers::HtmlHelpers.make_absolute_url(img["src"]) if img && img["src"]

        Models::PartInfo.new(
          name: clean_name(name, price, part_number, brand),
          part_number: part_number || "Unknown",
          brand: brand,
          price: price,
          url: url,
          image_url: image_url,
          info_url: info_url,
          video_url: nil,
          category: nil,
          specifications: nil,
          compatibility_notes: nil,
          listing_data: nil
        )
      rescue StandardError
        nil
      end

      def self.clean_name(text, price, part_number, brand)
        result = text.to_s.dup
        result = result.gsub(price, "") if price
        result = result.gsub(part_number, "") if part_number
        result = result.gsub(/#{Regexp.escape(brand)}/i, "") if brand
        result.gsub(/\s+/, " ").strip
      end
    end
  end
end
