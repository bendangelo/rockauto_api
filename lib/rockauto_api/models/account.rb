# frozen_string_literal: true

module RockautoApi
  module Models
    class SavedAddress < Dry::Struct
      attribute? :name, Types::String.optional
      attribute? :full_name, Types::String.optional
      attribute? :address_line1, Types::String.optional
      attribute? :address_line2, Types::String.optional
      attribute? :city, Types::String.optional
      attribute? :state, Types::String.optional
      attribute? :postal_code, Types::String.optional
      attribute? :country, Types::String.optional
      attribute? :phone, Types::String.optional
      attribute :is_default, Types::Bool.default(false)
      attribute? :address_id, Types::String.optional
    end

    class SavedAddressesResult < Dry::Struct
      attribute :addresses, Types::Array.of(SavedAddress)
      attribute :count, Types::Integer
      attribute :has_default, Types::Bool.default(false)
    end

    class SavedVehicle < Dry::Struct
      attribute :year, Types::Coercible::Integer
      attribute :make, Types::String
      attribute :model, Types::String
      attribute? :engine, Types::String.optional
      attribute? :carcode, Types::String.optional
      attribute? :display_name, Types::String.optional
      attribute? :catalog_url, Types::String.optional
      attribute? :vehicle_id, Types::String.optional
    end

    class SavedVehiclesResult < Dry::Struct
      attribute :vehicles, Types::Array.of(SavedVehicle)
      attribute :count, Types::Integer
    end

    class OrderHistoryItem < Dry::Struct
      attribute :order_number, Types::String
      attribute? :date, Types::String.optional
      attribute? :status, Types::String.optional
      attribute? :total, Types::String.optional
      attribute? :vehicle, Types::String.optional
      attribute? :order_url, Types::String.optional
    end

    class OrderHistoryResult < Dry::Struct
      attribute :orders, Types::Array.of(OrderHistoryItem)
      attribute :count, Types::Integer
      attribute? :filter_applied, Types::String.optional
      attribute? :search_time, Types::String.optional
    end

    class AccountActivityResult < Dry::Struct
      attribute :order_history, OrderHistoryResult.optional
      attribute :saved_addresses, SavedAddressesResult.optional
      attribute :saved_vehicles, SavedVehiclesResult.optional
      attribute :has_discount_codes, Types::Bool.default(false)
      attribute :has_store_credit, Types::Bool.default(false)
      attribute :has_alerts, Types::Bool.default(false)
    end
  end
end
