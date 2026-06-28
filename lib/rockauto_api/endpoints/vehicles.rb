# frozen_string_literal: true

module RockautoApi
  module Endpoints
    module Vehicles
      BASE_CATALOG_URL = "https://www.rockauto.com/en/catalog/"

      def get_makes
        html = get("/en/catalog/")
        results = Models::VehicleMakes.from_html(html)
        results
      end

      def get_years_for_make(make)
        simulate_navigation_context(make: make)

        path = "/en/catalog/#{make}"
        html = get(path)
        doc = Nokogiri::HTML(html)

        years = doc.css('a[href*="catalog"]').map { |a|
          href = a["href"]
          next nil if href.nil?
          match = href.match(/#{Regexp.escape(make)},(\d{4})/i)
          match ? match[1].to_i : nil
        }.compact.uniq.sort

        Models::VehicleYears.new(
          make: make,
          years: years,
          count: years.size
        )
      end

      def get_models_for_make_year(make, year)
        simulate_navigation_context(make: make, year: year.to_s)

        path = "/en/catalog/#{make},#{year}"
        html = get(path)
        doc = Nokogiri::HTML(html)

        models = doc.css('a[href*="catalog"]').map { |a|
          href = a["href"]
          next nil if href.nil?
          match = href.match(/#{Regexp.escape(make)},#{year},(.+)/i)
          next nil unless match
          model = match[1].split(",").first
          model&.strip
        }.compact.uniq

        Models::VehicleModels.new(
          make: make,
          year: year,
          models: models,
          count: models.size
        )
      end

      def get_engines_for_vehicle(make, year, model)
        path = "/en/catalog/#{make},#{year},#{model}"
        html = get(path)
        doc = Nokogiri::HTML(html)

        engines = doc.css('a[href*="carcode"]').map { |a|
          href = a["href"]
          next nil unless href
          match = href.match(/carcode=(\d+)/)
          next nil unless match
          Models::Engine.new(
            description: a.text.strip,
            carcode: match[1],
            href: Parsers::HtmlHelpers.make_absolute_url(href)
          )
        }.compact

        Models::VehicleEngines.new(
          make: make,
          year: year,
          model: model,
          engines: engines,
          count: engines.size
        )
      end
    end
  end
end
