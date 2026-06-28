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
      result = client.search_parts_by_number("45022-S9A-315")
      expect(result).to be_a(RockautoApi::Models::PartSearchResult)
      expect(result.search_term).to eq("45022-S9A-315")
    end
  end
end
