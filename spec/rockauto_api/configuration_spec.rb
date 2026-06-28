# frozen_string_literal: true

RSpec.describe RockautoApi::Configuration do
  subject(:config) { RockautoApi::Configuration.new }

  describe "defaults" do
    it "defaults to mobile" do
      expect(config.default_mobile).to be true
    end

    it "defaults to 30 second timeout" do
      expect(config.request_timeout).to eq(30)
    end

    it "has nil cache by default" do
      expect(config.cache).to be_nil
    end

    it "has nil credentials" do
      expect(config.credentials).to be_nil
    end
  end

  describe "#email" do
    it "returns nil when credentials not set" do
      expect(config.email).to be_nil
    end

    it "returns email from credentials" do
      config.credentials = { email: "test@example.com", password: "secret" }
      expect(config.email).to eq("test@example.com")
    end
  end

  describe "#password" do
    it "returns nil when credentials not set" do
      expect(config.password).to be_nil
    end

    it "returns password from credentials" do
      config.credentials = { email: "test@example.com", password: "secret" }
      expect(config.password).to eq("secret")
    end
  end

  describe "global configuration" do
    before { RockautoApi.configuration = nil }

    it "configures via block" do
      RockautoApi.configure do |c|
        c.request_timeout = 60
        c.default_mobile = false
      end
      expect(RockautoApi.configuration.request_timeout).to eq(60)
      expect(RockautoApi.configuration.default_mobile).to be false
    end
  end
end
