# frozen_string_literal: true

module RockautoApi
  module Parsers
    class OrderParser
      def self.parse(html)
        doc = Nokogiri::HTML(html)

        {
          order_number: extract_field(doc, /Order\s*#?/i),
          order_date: extract_field(doc, /Date/i),
          status: extract_field(doc, /Status/i),
          items: parse_items(doc),
          billing: parse_billing(doc),
          shipping: parse_shipping(doc)
        }
      end

      def self.extract_field(doc, pattern)
        doc.css("td, th, div, span").each do |el|
          if el.text.strip.match?(pattern)
            next_el = el.next_element || el.parent&.next_element
            return next_el.text.strip if next_el
          end
        end
        nil
      end

      def self.parse_items(doc)
        doc.css("table tr").map { |row|
          cells = row.css("td").map { |c| c.text.strip }
          next nil if cells.size < 3
          Models::OrderItem.new(
            part_number: cells[0] || "",
            description: cells[1] || "",
            brand: cells[2],
            quantity: cells[3],
            unit_price: cells[4],
            total_price: cells[5],
            status: cells[6],
            tracking_number: cells[7]
          )
        }.compact
      rescue StandardError
        []
      end

      def self.parse_billing(doc)
        Models::BillingInfo.new(
          subtotal: extract_field(doc, /Subtotal/i),
          shipping_cost: extract_field(doc, /Shipping/i),
          tax: extract_field(doc, /Tax/i),
          total: extract_field(doc, /Total/i)
        )
      end

      def self.parse_shipping(doc)
        Models::ShippingInfo.new(
          method: extract_field(doc, /Method/i),
          carrier: extract_field(doc, /Carrier/i),
          tracking_number: extract_field(doc, /Tracking/i)
        )
      end
    end
  end
end
