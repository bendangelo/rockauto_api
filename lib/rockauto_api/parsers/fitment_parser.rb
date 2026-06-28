# frozen_string_literal: true

module RockautoApi
  module Parsers
    class FitmentParser
      def self.parse(html, part_number:, brand:)
        fitments = []

        if html && !html.empty?
          doc = Nokogiri::HTML(html)
          doc.css("table tr").each do |row|
            cells = row.css("td, th").map { |c| c.text.strip }
            next if cells.size < 3
            next if cells.first.match?(/\A\s*(?:Year|Make|Model)\s*\z/i)

            year = cells[0].to_i
            if year.zero?
              year = cells[2].to_i
              make = cells[0] || "Unknown"
              model = cells[1] || "Unknown"
            else
              make = cells[1] || "Unknown"
              model = cells[2] || "Unknown"
            end

            next if year.zero?

            fitments << Models::FitmentInfo.new(
              year: year,
              make: make,
              model: model,
              engine: cells[3],
              transmission: cells[4],
              drivetrain: cells[5],
              notes: cells[6]
            )
          end
        end

        Models::BuyersGuideResult.new(
          part_number: part_number,
          brand: brand,
          fitments: fitments,
          count: fitments.size
        )
      end
    end
  end
end
