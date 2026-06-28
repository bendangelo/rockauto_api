# frozen_string_literal: true

RSpec.describe "Orders endpoints", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#lookup_order_status" do
    it "returns an OrderStatusResult for any lookup" do
      result = client.lookup_order_status("test@example.com", "INVALID-ORDER")
      expect(result).to be_a(RockautoApi::Models::OrderStatusResult)
    end
  end

  describe "#request_order_list" do
    it "returns true when requesting by email" do
      result = client.request_order_list(:email, "test@example.com")
      expect(result).to be true
    end
  end
end
