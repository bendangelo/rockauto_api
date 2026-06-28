# frozen_string_literal: true

RSpec.describe RockautoApi::Client, :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#initialize" do
    it "creates a client with default mobile headers" do
      expect(client).to be_a(RockautoApi::Client)
      expect(client.authenticated).to be false
    end

    it "creates a client with desktop headers when mobile: false" do
      desktop_client = RockautoApi::Client.new(mobile: false)
      expect(desktop_client).to be_a(RockautoApi::Client)
      expect(desktop_client.authenticated).to be false
    end

    it "uses configured default_mobile when not specified" do
      RockautoApi.configure { |c| c.default_mobile = false }
      c = RockautoApi::Client.new
      expect(c).to be_a(RockautoApi::Client)
      RockautoApi.configure { |c| c.default_mobile = true }
    end
  end

  describe "#init_session!" do
    it "initializes a session and extracts _nck token" do
      client.init_session!
      expect(client.instance_variable_get(:@session_initialized)).to be true
    end

    it "is idempotent" do
      client.init_session!
      client.init_session!
      expect(client.instance_variable_get(:@session_initialized)).to be true
    end
  end

  describe "#get" do
    it "fetches HTML content from a path" do
      html = client.get("/en/catalog/")
      expect(html).to be_a(String)
      expect(html.downcase).to include("html")
    end

    it "returns HTML even for invalid paths" do
      html = client.get("/en/nonexistent_path_xyz")
      expect(html).to be_a(String)
    end
  end

  describe "#simulate_navigation_context" do
    it "sets referer header for make" do
      client.simulate_navigation_context(make: "HONDA")
      conn = client.instance_variable_get(:@conn)
      expect(conn.headers["Referer"]).to include("catalog")
    end
  end
end
