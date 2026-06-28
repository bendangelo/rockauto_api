# frozen_string_literal: true

module RockautoApi
  module Endpoints
    module Orders
      def lookup_order_status(email_or_phone, order_number)
        form_data = {
          "email" => email_or_phone.include?("@") ? email_or_phone : "",
          "phone" => email_or_phone.include?("@") ? "" : email_or_phone,
          "order_number" => order_number
        }

        html = post_with_csrf("/orderstatus/", form_data)
        parsed = Parsers::OrderParser.parse(html)

        if parsed[:order_number]
          Models::OrderStatusResult.new(
            success: true,
            order: Models::OrderStatus.new(**parsed),
            error: nil
          )
        else
          Models::OrderStatusResult.new(
            success: false,
            order: nil,
            error: Models::OrderStatusError.new(
              error_type: "not_found",
              message: "Order not found",
              order_number: order_number,
              suggestions: ["Check the order number", "Try searching by email instead"]
            )
          )
        end
      end

      def request_order_list(method, contact)
        case method.to_s
        when "email"
          post_with_csrf("/orderstatus/", { "send_email" => "1", "email" => contact })
        when "sms"
          post_with_csrf("/orderstatus/", { "send_sms" => "1", "phone" => contact })
        else
          false
        end
        true
      rescue StandardError
        false
      end
    end
  end
end
