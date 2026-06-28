# frozen_string_literal: true

module RockautoApi
  module Models
    class OrderItem < Dry::Struct
      attribute :part_number, Types::String
      attribute :description, Types::String
      attribute? :brand, Types::String.optional
      attribute? :quantity, Types::String.optional
      attribute? :unit_price, Types::String.optional
      attribute? :total_price, Types::String.optional
      attribute? :status, Types::String.optional
      attribute? :tracking_number, Types::String.optional
    end

    class BillingInfo < Dry::Struct
      attribute? :subtotal, Types::String.optional
      attribute? :shipping_cost, Types::String.optional
      attribute? :tax, Types::String.optional
      attribute? :total, Types::String.optional
      attribute? :payment_method, Types::String.optional
      attribute? :payment_status, Types::String.optional
    end

    class ShippingInfo < Dry::Struct
      attribute? :method, Types::String.optional
      attribute? :cost, Types::String.optional
      attribute? :carrier, Types::String.optional
      attribute? :tracking_number, Types::String.optional
      attribute? :estimated_delivery, Types::String.optional
      attribute? :actual_delivery, Types::String.optional
    end

    class OrderStatus < Dry::Struct
      attribute :order_number, Types::String
      attribute? :order_date, Types::String.optional
      attribute? :status, Types::String.optional
      attribute? :customer_email, Types::String.optional
      attribute? :customer_phone, Types::String.optional
      attribute :items, Types::Array.of(OrderItem).default([].freeze)
      attribute :billing, BillingInfo.optional
      attribute :shipping, ShippingInfo.optional
      attribute? :notes, Types::String.optional
      attribute? :return_eligibility, Types::String.optional
    end

    class OrderStatusError < Dry::Struct
      attribute :error_type, Types::String
      attribute :message, Types::String
      attribute :order_number, Types::String
      attribute :suggestions, Types::Array.of(Types::String).default([].freeze)
    end

    class OrderStatusResult < Dry::Struct
      attribute :success, Types::Bool
      attribute :order, OrderStatus.optional
      attribute :error, OrderStatusError.optional
      attribute? :lookup_time, Types::String.optional
    end
  end
end
