# frozen_string_literal: true

RSpec.describe "Part Search endpoints", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#get_manufacturers" do
    it "returns manufacturer options" do
      result = client.get_manufacturers
      expect(result).to be_a(RockautoApi::Models::ManufacturerOptions)
      expect(result.count).to be > 0
      expect(result.manufacturers).to all be_a(RockautoApi::Models::PartSearchOption)
    end
  end

  describe "#get_part_groups" do
    it "returns part group options" do
      result = client.get_part_groups
      expect(result).to be_a(RockautoApi::Models::PartGroupOptions)
      expect(result.count).to be > 0
    end
  end

  describe "#get_part_types" do
    it "returns part type options" do
      result = client.get_part_types
      expect(result).to be_a(RockautoApi::Models::PartTypeOptions)
      expect(result.count).to be > 0
    end
  end

  describe "#what_is_part_called" do
    it "returns search results for a query" do
      result = client.what_is_part_called("brake pad")
      expect(result).to be_a(RockautoApi::Models::WhatIsPartCalledResults)
      expect(result.count).to be >= 0
      expect(result.search_term).to eq("brake pad")
    end
  end

  describe "#search_parts_by_number" do
    it "returns parts for a part number" do
      result = client.search_parts_by_number("FG0326")
      expect(result).to be_a(RockautoApi::Models::PartSearchResult)
      expect(result.search_term).to eq("FG0326")
      expect(result.count).to be > 0
      expect(result.parts).to all be_a(RockautoApi::Models::PartInfo)
      result.parts.each do |part|
        expect(part.part_number).not_to eq("Unknown")
        expect(part.brand).not_to be_nil
      end
    end

    it "does not return captcha or bot detection content" do
      result = client.search_parts_by_number("45022-S9A-315")
      expect(result).to be_a(RockautoApi::Models::PartSearchResult)
      suspicious = /email|password|security|captcha|submit|reset|privacy/i
      result.parts.each do |part|
        expect(part.name).not_to match(suspicious)
        expect(part.part_number).not_to eq("Unknown")
      end
    end

    describe "with fitments" do
      it "includes buyers guide fitment data", cassette: "part_search_with_fitments" do
        result = client.search_parts_by_number("FG0326", include_fitments: true)
        expect(result).to be_a(RockautoApi::Models::PartSearchResult)
        expect(result.count).to be > 0

        parts_with_fitments = result.parts.select { |p| p.buyers_guide&.fitments&.any? }
        expect(parts_with_fitments).not_to be_empty,
          "Expected at least one part to have fitment data"

        parts_with_fitments.each do |part|
          bg = part.buyers_guide
          expect(bg).to be_a(RockautoApi::Models::BuyersGuideResult)
          expect(bg.part_number).to eq(part.part_number)
          expect(bg.fitments).to all be_a(RockautoApi::Models::FitmentInfo)
          bg.fitments.each do |fitment|
            expect(fitment.year).to be > 0
            expect(fitment.make).not_to be_empty
            expect(fitment.model).not_to be_empty
          end
        end
      end
    end
  end
end
