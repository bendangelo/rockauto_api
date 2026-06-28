# frozen_string_literal: true

module RockautoApi
  module Endpoints
    module Account
      LOGIN_URL = "https://www.rockauto.com/catalog/catalogapi.php"
      PROFILE_URL = "/en/profile/"
      ORDER_HISTORY_URL = "/en/orderhistory/"

      def login(email, password)
        payload = {
          "jsn" => {
            "email" => email,
            "password" => password,
            "keep_me_logged_in" => false
          }
        }

        response = call_catalog_api("login", payload)
        @authenticated = response["success"] == true || response.dig("response", "success") == true
        @authenticated
      rescue NetworkError
        @authenticated = false
      end

      def logout
        response = call_catalog_api("logout", {})
        @authenticated = false
        true
      rescue StandardError
        @authenticated = false
        true
      end

      def authenticated?
        @authenticated
      end

      def get_saved_addresses
        require_authentication!
        html = get(PROFILE_URL)
        doc = Nokogiri::HTML(html)

        addresses = doc.css("table tr").map { |row|
          cells = row.css("td").map { |c| c.text.strip }
          next nil if cells.size < 5

          Models::SavedAddress.new(
            name: cells[0],
            full_name: cells[1],
            address_line1: cells[2],
            city: cells[3],
            state: cells[4],
            postal_code: cells[5],
            country: cells[6] || "US",
            phone: cells[7]
          )
        }.compact

        Models::SavedAddressesResult.new(
          addresses: addresses,
          count: addresses.size,
          has_default: addresses.any? { |a| a.name&.downcase&.include?("default") }
        )
      end

      def get_saved_vehicles
        require_authentication!
        html = get(PROFILE_URL)
        doc = Nokogiri::HTML(html)

        vehicles = doc.css("a[href*='carcode']").map { |a|
          href = a["href"]
          text = a.text.strip
          match = href&.match(/carcode=(\d+)/)

          parts = text.split(" ")
          year = parts[0].to_i

          Models::SavedVehicle.new(
            year: year,
            make: parts[1] || "",
            model: parts[2] || "",
            engine: parts[3..]&.join(" "),
            carcode: match&.captures&.first,
            display_name: text,
            catalog_url: Parsers::HtmlHelpers.make_absolute_url(href)
          )
        }.compact

        Models::SavedVehiclesResult.new(
          vehicles: vehicles,
          count: vehicles.size
        )
      end

      def get_account_activity
        addresses = get_saved_addresses
        vehicles = get_saved_vehicles

        Models::AccountActivityResult.new(
          saved_addresses: addresses,
          saved_vehicles: vehicles,
          order_history: nil,
          has_discount_codes: false,
          has_store_credit: false,
          has_alerts: false
        )
      end

      def get_order_history(filter_params = {})
        require_authentication!
        html = get(ORDER_HISTORY_URL)
        doc = Nokogiri::HTML(html)

        orders = doc.css("table tr").map { |row|
          cells = row.css("td").map { |c| c.text.strip }
          next nil if cells.size < 3
          next nil if cells[0].match?(/\A\s*(?:Order|Date|Status)\s*\z/i)

          Models::OrderHistoryItem.new(
            order_number: cells[0] || "",
            date: cells[1],
            status: cells[2],
            total: cells[3],
            vehicle: cells[4],
            order_url: nil
          )
        }.compact

        Models::OrderHistoryResult.new(
          orders: orders,
          count: orders.size,
          filter_applied: filter_params.empty? ? nil : filter_params.to_s,
          search_time: Time.now.iso8601
        )
      end

      def add_external_order(email_or_phone, order_number)
        require_authentication!
        form_data = {
          "email" => email_or_phone.include?("@") ? email_or_phone : "",
          "phone" => email_or_phone.include?("@") ? "" : email_or_phone,
          "order_number" => order_number
        }
        post_with_csrf("/en/orderhistory/addorder/", form_data)
        true
      rescue StandardError
        false
      end

      private

      def require_authentication!
        raise AuthenticationError, "Not authenticated. Call login(email, password) first." unless @authenticated
      end
    end
  end
end
