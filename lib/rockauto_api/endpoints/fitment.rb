# frozen_string_literal: true

module RockautoApi
  module Endpoints
    module Fitment
      def get_fitment_for_part(listing_data)
        return default_result("", "") unless listing_data.is_a?(Hash) && !listing_data.empty?

        car_data = listing_data["car"] || listing_data[:car] || {}
        supp_data = listing_data["supplemental"] || listing_data[:supplemental] || {}

        part_number = supp_data["partnumber"] || supp_data[:partnumber] || ""
        brand = supp_data["catalogname"] || supp_data[:catalogname] || ""

        cache_key = "rockauto:fitment:#{part_number}:#{brand}"

        cache.fetch(cache_key, ttl: 604800) do
          payload = {
            "partData" => {
              "groupindex" => listing_data["groupindex"] || listing_data[:groupindex] || "0",
              "listing_data_essential" => {
                "groupindex" => listing_data["groupindex"] || listing_data[:groupindex] || "0",
                "carcode" => car_data["carcode"] || car_data[:carcode] || 0,
                "parttype" => car_data["parttype"] || car_data[:parttype] || "",
                "partkey" => car_data["partkey"] || car_data[:partkey] || ""
              },
              "listing_data_supplemental" => {
                "partnumber" => part_number,
                "catalogname" => brand,
                "belongstolisting" => "2",
                "sortgroup" => 0,
                "sortgrouptext" => "",
                "paramdesc" => "",
                "showhide" => {}
              },
              "OptKey" => listing_data["optkey"] || listing_data[:optkey] || ""
            }
          }

          response = call_catalog_api("getbuyersguide", payload)
          html = response.dig("buyersguidepieces", "body")

          Parsers::FitmentParser.parse(html, part_number: part_number, brand: brand)
        end
      rescue NetworkError, ParseError
        default_result(part_number, brand)
      end

      private

      def default_result(part_number, brand)
        Models::BuyersGuideResult.new(
          part_number: part_number,
          brand: brand,
          fitments: [],
          count: 0
        )
      end
    end
  end
end
