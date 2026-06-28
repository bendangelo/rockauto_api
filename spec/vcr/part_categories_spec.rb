# frozen_string_literal: true

RSpec.describe "Part Categories endpoints", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#get_part_categories" do
    it "returns categories for a vehicle" do
      result = client.get_part_categories("ACURA", 2020, "MDX", "3444459")
      expect(result).to be_a(RockautoApi::Models::VehiclePartCategories)
      expect(result.make).to eq("ACURA")
      expect(result.year).to eq(2020)
      expect(result.model).to eq("MDX")
      expect(result.count).to be > 0
      expect(result.categories).to all be_a(RockautoApi::Models::PartCategory)
      expect(result.categories.first).to respond_to(:name, :group_name, :href)
    end
  end

  describe "#get_parts_by_category" do
    it "returns parts for a vehicle category" do
      categories = client.get_part_categories("ACURA", 2020, "MDX", "3444459")
      first_cat = categories.categories.first
      result = client.get_parts_by_category("ACURA", 2020, "MDX", "3444459", first_cat.group_name)
      expect(result).to be_a(RockautoApi::Models::VehiclePartsResult)
      expect(result.make).to eq("ACURA")
      expect(result.count).to be >= 0
    end
  end
end
