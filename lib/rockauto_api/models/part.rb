# frozen_string_literal: true

module RockautoApi
  module Models
    class PartInfo < Dry::Struct
      attribute :name, Types::String
      attribute :part_number, Types::String
      attribute? :brand, Types::String.optional
      attribute? :price, Types::String.optional
      attribute? :url, Types::String.optional
      attribute? :image_url, Types::String.optional
      attribute? :info_url, Types::String.optional
      attribute? :video_url, Types::String.optional
      attribute? :category, Types::String.optional
      attribute? :specifications, Types::String.optional
      attribute? :compatibility_notes, Types::String.optional
      attribute? :listing_data, Types::Hash
      attribute? :buyers_guide, Types.Instance(RockautoApi::Models::BuyersGuideResult)
    end

    class PartSearchResult < Dry::Struct
      attribute :parts, Types::Array.of(PartInfo)
      attribute :count, Types::Integer
      attribute :search_term, Types::String
      attribute :manufacturer, Types::String.default("All")
      attribute :part_group, Types::String.default("All")
    end

    class PartSearchOption < Dry::Struct
      attribute :value, Types::String
      attribute :text, Types::String
    end

    class ManufacturerOptions < Dry::Struct
      attribute :manufacturers, Types::Array.of(PartSearchOption)
      attribute :count, Types::Integer
      attribute? :last_updated, Types::String.optional

      def lookup(name)
        manufacturers.find { |m| m.text.casecmp(name).zero? }
      end
    end

    class PartGroupOptions < Dry::Struct
      attribute :part_groups, Types::Array.of(PartSearchOption)
      attribute :count, Types::Integer
      attribute? :last_updated, Types::String.optional

      def lookup(name)
        part_groups.find { |g| g.text.casecmp(name).zero? }
      end
    end

    class PartTypeOptions < Dry::Struct
      attribute :part_types, Types::Array.of(PartSearchOption)
      attribute :count, Types::Integer
      attribute? :last_updated, Types::String.optional

      def lookup(name)
        part_types.find { |t| t.text.casecmp(name).zero? }
      end
    end

    class WhatIsPartCalledResult < Dry::Struct
      attribute :main_category, Types::String
      attribute :subcategory, Types::String
      attribute :full_path, Types::String
    end

    class WhatIsPartCalledResults < Dry::Struct
      attribute :results, Types::Array.of(WhatIsPartCalledResult)
      attribute :count, Types::Integer
      attribute :search_term, Types::String
    end
  end
end
