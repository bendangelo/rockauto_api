# frozen_string_literal: true

RSpec.describe "Vehicles endpoints", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#get_makes" do
    it "returns vehicle makes" do
      result = client.get_makes
      expect(result).to be_a(RockautoApi::Models::VehicleMakes)
      expect(result.count).to be > 0
      expect(result.makes).to all be_a(String)
      expect(result.makes).to include("ACURA")
    end
  end

  describe "#get_years_for_make" do
    it "returns years for a given make" do
      result = client.get_years_for_make("ACURA")
      expect(result).to be_a(RockautoApi::Models::VehicleYears)
      expect(result.make).to eq("ACURA")
      expect(result.count).to be > 0
      expect(result.years).to all be_a(Integer)
    end
  end

  describe "#get_models_for_make_year" do
    it "returns models for a make and year" do
      result = client.get_models_for_make_year("ACURA", 2020)
      expect(result).to be_a(RockautoApi::Models::VehicleModels)
      expect(result.make).to eq("ACURA")
      expect(result.year).to eq(2020)
      expect(result.count).to be > 0
      expect(result.models).to all be_a(String)
    end
  end

  describe "#get_engines_for_vehicle" do
    it "returns engines array for a vehicle" do
      result = client.get_engines_for_vehicle("ACURA", 2020, "MDX")
      expect(result).to be_a(RockautoApi::Models::VehicleEngines)
      expect(result.make).to eq("ACURA")
      expect(result.year).to eq(2020)
      expect(result.model).to eq("MDX")
    end
  end
end
