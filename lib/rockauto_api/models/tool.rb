# frozen_string_literal: true

module RockautoApi
  module Models
    class ToolCategory < Dry::Struct
      attribute :name, Types::String
      attribute :group_name, Types::String
      attribute? :href, Types::String.optional
      attribute :level, Types::Integer.default(0)
    end

    class ToolCategories < Dry::Struct
      attribute :categories, Types::Array.of(ToolCategory)
      attribute :count, Types::Integer
      attribute :level, Types::Integer.default(0)
      attribute? :parent_path, Types::String.optional
    end

    class ToolInfo < Dry::Struct
      attribute :name, Types::String
      attribute :part_number, Types::String
      attribute? :brand, Types::String.optional
      attribute? :description, Types::String.optional
      attribute? :url, Types::String.optional
      attribute? :image_url, Types::String.optional
      attribute? :info_url, Types::String.optional
      attribute? :video_url, Types::String.optional
      attribute? :specifications, Types::String.optional
      attribute? :category, Types::String.optional
      attribute? :features, Types::String.optional
      attribute? :warranty_info, Types::String.optional
    end

    class ToolsResult < Dry::Struct
      attribute :tools, Types::Array.of(ToolInfo)
      attribute :count, Types::Integer
      attribute :category, Types::String
      attribute? :category_path, Types::String.optional
    end
  end
end
