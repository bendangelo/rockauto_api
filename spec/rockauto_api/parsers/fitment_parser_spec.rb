# frozen_string_literal: true

RSpec.describe RockautoApi::Parsers::FitmentParser do
  describe ".parse" do
    it "extracts fitment info from buyersguide HTML" do
      html = <<~HTML
        <table>
          <tr><td>2020</td><td>Ford</td><td>F-150</td><td>3.5L V6</td><td>Automatic</td></tr>
          <tr><td>2021</td><td>Ford</td><td>F-150</td><td>5.0L V8</td><td>Automatic</td></tr>
          <tr><td>2019</td><td>Ford</td><td>Expedition</td><td>3.5L V6</td><td>Automatic</td></tr>
        </table>
      HTML

      result = described_class.parse(html, part_number: "FG0326", brand: "DELPHI")

      expect(result).to be_a(RockautoApi::Models::BuyersGuideResult)
      expect(result.part_number).to eq("FG0326")
      expect(result.brand).to eq("DELPHI")
      expect(result.fitments.size).to eq(3)
      expect(result.fitments.first.year).to eq(2020)
      expect(result.fitments.first.make).to eq("Ford")
      expect(result.fitments.first.model).to eq("F-150")
      expect(result.count).to eq(3)
    end

    it "handles empty HTML" do
      result = described_class.parse("<table></table>", part_number: "X", brand: "Y")
      expect(result.fitments).to be_empty
      expect(result.count).to eq(0)
    end

    it "handles nil HTML" do
      result = described_class.parse(nil, part_number: "X", brand: "Y")
      expect(result.fitments).to be_empty
    end
  end
end
