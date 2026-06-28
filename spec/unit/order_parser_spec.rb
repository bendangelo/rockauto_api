# frozen_string_literal: true

RSpec.describe RockautoApi::Parsers::OrderParser, :unit do
  describe ".parse" do
    it "extracts order details from HTML" do
      html = File.read("spec/fixtures/html/order_status_found.html")
      result = described_class.parse(html)
      expect(result[:order_number]).to eq("RA-123456")
      expect(result[:status]).to eq("Shipped")
      expect(result[:items]).to be_an(Array)
      expect(result[:items].size).to eq(1)
      expect(result[:items].first.part_number).to eq("45022-S9A-315")
    end

    it "handles empty HTML gracefully" do
      result = described_class.parse("<html><body></body></html>")
      expect(result).to be_a(Hash)
      expect(result[:items]).to eq([])
    end
  end
end
