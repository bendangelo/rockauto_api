# frozen_string_literal: true

module RockautoApi
  module Types
    include Dry.Types()
  end

  module Models
    class VehicleMakes < Dry::Struct
      attribute :makes, Types::Array.of(Types::String)
      attribute :count, Types::Integer

      def self.from_html(html)
        doc = Nokogiri::HTML(html)
        makes = doc.css('a[href*="/en/catalog/"]').map { |a|
          href = a["href"]
          next nil if href.nil? || href == "/en/catalog/" || href.include?(",")
          a.text.strip
        }.compact.uniq
        new(makes: makes, count: makes.size)
      end
    end

    class VehicleYears < Dry::Struct
      attribute :make, Types::String
      attribute :years, Types::Array.of(Types::Integer)
      attribute :count, Types::Integer
    end

    class VehicleModels < Dry::Struct
      attribute :make, Types::String
      attribute :year, Types::Integer
      attribute :models, Types::Array.of(Types::String)
      attribute :count, Types::Integer
    end

    class Engine < Dry::Struct
      attribute :description, Types::String
      attribute :carcode, Types::String
      attribute? :href, Types::String.optional
    end

    class VehicleEngines < Dry::Struct
      attribute :make, Types::String
      attribute :year, Types::Integer
      attribute :model, Types::String
      attribute :engines, Types::Array.of(Engine)
      attribute :count, Types::Integer
    end

    class PartCategory < Dry::Struct
      attribute :name, Types::String
      attribute :group_name, Types::String
      attribute? :href, Types::String.optional
    end

    class VehiclePartCategories < Dry::Struct
      attribute :make, Types::String
      attribute :year, Types::Integer
      attribute :model, Types::String
      attribute :carcode, Types::String
      attribute :categories, Types::Array.of(PartCategory)
      attribute :count, Types::Integer
    end

    class VehiclePartsResult < Dry::Struct
      attribute :make, Types::String
      attribute :year, Types::Integer
      attribute :model, Types::String
      attribute :carcode, Types::String
      attribute :category, Types::String
      attribute :parts, Types::Array
      attribute :count, Types::Integer
    end
  end
end
