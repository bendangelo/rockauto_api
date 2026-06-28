# frozen_string_literal: true

module RockautoApi
  module Models
    class FitmentInfo < Dry::Struct
      attribute :year, Types::Integer
      attribute :make, Types::String
      attribute :model, Types::String
      attribute? :engine, Types::String.optional
      attribute? :transmission, Types::String.optional
      attribute? :drivetrain, Types::String.optional
      attribute? :notes, Types::String.optional
    end

    class BuyersGuideResult < Dry::Struct
      attribute :part_number, Types::String
      attribute :brand, Types::String
      attribute :fitments, Types::Array.of(FitmentInfo)
      attribute :count, Types::Integer
    end
  end
end
