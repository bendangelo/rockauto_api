# frozen_string_literal: true

RSpec.describe "Fitment endpoint", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#get_fitment_for_part" do
    it "returns default result for empty listing data" do
      result = client.get_fitment_for_part({})
      expect(result).to be_a(RockautoApi::Models::BuyersGuideResult)
      expect(result.count).to eq(0)
      expect(result.part_number).to eq("")
    end

    it "handles nil listing data" do
      result = client.get_fitment_for_part(nil)
      expect(result).to be_a(RockautoApi::Models::BuyersGuideResult)
      expect(result.count).to eq(0)
    end
  end
end
