# frozen_string_literal: true

RSpec.describe "Tools endpoints", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#get_tool_categories" do
    it "returns tool categories" do
      result = client.get_tool_categories
      expect(result).to be_a(RockautoApi::Models::ToolCategories)
      expect(result.count).to be > 0
      expect(result.categories).to all be_a(RockautoApi::Models::ToolCategory)
      expect(result.categories.first).to respond_to(:name, :group_name, :href, :level)
    end
  end

  describe "#get_tools_by_category" do
    it "returns tools for a category" do
      categories = client.get_tool_categories
      first_cat = categories.categories.first
      skip "No categories available" unless first_cat&.href
      result = client.get_tools_by_category(first_cat.href)
      expect(result).to be_a(RockautoApi::Models::ToolsResult)
      expect(result.count).to be >= 0
    end
  end
end
