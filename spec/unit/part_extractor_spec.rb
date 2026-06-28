# frozen_string_literal: true

RSpec.describe RockautoApi::Parsers::PartExtractor, :unit do
  describe ".extract_from_row" do
    it "extracts part info from a table row" do
      html = File.read("spec/fixtures/html/part_row.html")
      doc = Nokogiri::HTML(html)
      row = doc.at_css("tr")
      result = described_class.extract_from_row(row)
      expect(result).to be_a(RockautoApi::Models::PartInfo)
      expect(result.part_number).to eq("45022S9A315")
      expect(result.price).to eq("$45.99")
    end

    it "returns nil for empty row" do
      doc = Nokogiri::HTML("<html><body><table><tr></tr></table></body></html>")
      row = doc.at_css("tr")
      result = described_class.extract_from_row(row)
      expect(result).to be_nil
    end
  end
end
