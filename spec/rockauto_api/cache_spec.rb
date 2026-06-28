# frozen_string_literal: true

RSpec.describe RockautoApi::Cache do
  describe "#fetch" do
    it "caches values with in-memory fallback" do
      cache = RockautoApi::Cache.new
      call_count = 0

      result1 = cache.fetch("key1", ttl: 60) { call_count += 1; "value1" }
      result2 = cache.fetch("key1", ttl: 60) { call_count += 1; "value2" }

      expect(result1).to eq("value1")
      expect(result2).to eq("value1")
      expect(call_count).to eq(1)
    end

    it "returns fresh values for different keys" do
      cache = RockautoApi::Cache.new
      call_count = 0

      cache.fetch("a") { call_count += 1; "A" }
      cache.fetch("b") { call_count += 1; "B" }

      expect(call_count).to eq(2)
      expect(cache.fetch("a") { "X" }).to eq("A")
    end
  end

  describe "#delete" do
    it "removes a cached entry" do
      cache = RockautoApi::Cache.new
      cache.fetch("key") { "value" }
      cache.delete("key")
      expect(cache.fetch("key") { "new" }).to eq("new")
    end
  end

  describe "#clear" do
    it "removes all cached entries" do
      cache = RockautoApi::Cache.new
      cache.fetch("a") { "A" }
      cache.fetch("b") { "B" }
      cache.clear
      expect(cache.fetch("a") { "X" }).to eq("X")
      expect(cache.fetch("b") { "Y" }).to eq("Y")
    end
  end

  describe "with external store" do
    it "delegates to the external store" do
      store = double("store")
      allow(store).to receive(:fetch).with("key", expires_in: 60).and_yield.and_return("stored")
      cache = RockautoApi::Cache.new(store: store)
      expect(cache.fetch("key", ttl: 60) { "fallback" }).to eq("stored")
    end
  end
end
