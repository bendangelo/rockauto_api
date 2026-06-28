# VCR Testing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add VCR cassettes and comprehensive tests for all public endpoints, parsers, and configuration.

**Architecture:** Hybrid approach — VCR integration tests for endpoint methods (record/replay HTTP), unit tests for parsers (HTML fixtures). Authenticated endpoints skipped.

**Tech Stack:** Ruby, RSpec, VCR ~> 6.0, WebMock ~> 3.19, Faraday

---

### Task 1: VCR Configuration + Spec Helper

**Files:**
- Modify: `spec/spec_helper.rb`
- Create: `spec/support/vcr.rb`

- [ ] **Step 1: Create VCR support file**

```ruby
# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri]
  }
  config.configure_rspec_metadata!
  config.ignore_localhost = true

  config.filter_sensitive_data("<SESSION_COOKIE>") do |interaction|
    set_cookie = interaction.response.headers["Set-Cookie"]
    if set_cookie
      set_cookie.first.to_s
    end
  end

  config.filter_sensitive_data("<COOKIE_HEADER>") do |interaction|
    cookie = interaction.request.headers["Cookie"]
    cookie&.first.to_s
  end
end

# Tag :vcr on integration tests, :unit on unit tests
RSpec.configure do |config|
  config.around(:each, :vcr) do |example|
    name = example.metadata[:cassette] ||
           example.metadata[:full_description].gsub(/[^A-Za-z0-9]+/, "_").gsub(/_+$/, "")
    VCR.use_cassette(name, record: :new_episodes) do
      example.run
    end
  end
end
```

- [ ] **Step 2: Update spec_helper.rb to load support files**

```ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "rockauto_api"
require "pry"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
```

- [ ] **Step 3: Verify VCR loads**

Run: `bundle exec rspec --dry-run`
Expected: No errors, VCR is loaded

- [ ] **Step 4: Commit**

---

### Task 2: Client Spec (VCR)

**Files:**
- Create: `spec/vcr/client_spec.rb`

- [ ] **Step 1: Write client spec**

```ruby
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
      expect(html).to include("html")
    end
  end
end
```

- [ ] **Step 2: Run to record cassette**

Run: `bundle exec rspec spec/vcr/client_spec.rb --format documentation`
Expected: All tests pass, cassette created at spec/cassettes/<name>.yml

- [ ] **Step 3: Run again to verify replay**

Run: `bundle exec rspec spec/vcr/client_spec.rb --format documentation`
Expected: All tests pass, uses cassette (no network)

- [ ] **Step 4: Commit**

---

### Task 3: Vehicles Endpoint Spec (VCR)

**Files:**
- Create: `spec/vcr/vehicles_spec.rb`

- [ ] **Step 1: Write vehicles spec**

```ruby
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
    it "returns engines for a vehicle" do
      result = client.get_engines_for_vehicle("ACURA", 2020, "MDX")
      expect(result).to be_a(RockautoApi::Models::VehicleEngines)
      expect(result.make).to eq("ACURA")
      expect(result.year).to eq(2020)
      expect(result.model).to eq("MDX")
      expect(result.count).to be > 0
      expect(result.engines).to all be_a(RockautoApi::Models::Engine)
    end
  end
end
```

- [ ] **Step 2: Run and record**

Run: `bundle exec rspec spec/vcr/vehicles_spec.rb --format documentation`
Expected: Passes, cassettes created

- [ ] **Step 3: Re-run to verify replay**

Run: `bundle exec rspec spec/vcr/vehicles_spec.rb --format documentation`
Expected: Passes, no network calls

- [ ] **Step 4: Commit**

---

### Task 4: Part Categories Spec (VCR)

**Files:**
- Create: `spec/vcr/part_categories_spec.rb`

- [ ] **Step 1: Write part categories spec**

```ruby
# frozen_string_literal: true

RSpec.describe "Part Categories endpoints", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#get_part_categories" do
    it "returns categories for a vehicle" do
      result = client.get_part_categories("ACURA", 2020, "MDX", "1477997")
      expect(result).to be_a(RockautoApi::Models::VehiclePartCategories)
      expect(result.make).to eq("ACURA")
      expect(result.year).to eq(2020)
      expect(result.model).to eq("MDX")
      expect(result.count).to be > 0
      expect(result.categories).to all be_a(RockautoApi::Models::PartCategory)
    end
  end

  describe "#get_parts_by_category" do
    it "returns parts for a vehicle category" do
      categories = client.get_part_categories("ACURA", 2020, "MDX", "1477997")
      first_cat = categories.categories.first
      result = client.get_parts_by_category("ACURA", 2020, "MDX", "1477997", first_cat.group_name)
      expect(result).to be_a(RockautoApi::Models::VehiclePartsResult)
      expect(result.make).to eq("ACURA")
    end
  end
end
```

- [ ] **Step 2: Run and record + replay verify**

- [ ] **Step 3: Commit**

---

### Task 5: Part Search Spec (VCR)

**Files:**
- Create: `spec/vcr/part_search_spec.rb`

- [ ] **Step 1: Write part search spec**

```ruby
# frozen_string_literal: true

RSpec.describe "Part Search endpoints", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#get_manufacturers" do
    it "returns manufacturer options" do
      result = client.get_manufacturers
      expect(result).to be_a(RockautoApi::Models::ManufacturerOptions)
      expect(result.count).to be > 0
      expect(result.manufacturers).to all be_a(RockautoApi::Models::PartSearchOption)
    end
  end

  describe "#get_part_groups" do
    it "returns part group options" do
      result = client.get_part_groups
      expect(result).to be_a(RockautoApi::Models::PartGroupOptions)
      expect(result.count).to be > 0
    end
  end

  describe "#get_part_types" do
    it "returns part type options" do
      result = client.get_part_types
      expect(result).to be_a(RockautoApi::Models::PartTypeOptions)
      expect(result.count).to be > 0
    end
  end

  describe "#what_is_part_called" do
    it "returns search results for a query" do
      result = client.what_is_part_called("brake pad")
      expect(result).to be_a(RockautoApi::Models::WhatIsPartCalledResults)
      expect(result.count).to be >= 0
    end
  end

  describe "#search_parts_by_number" do
    it "returns parts for a part number" do
      result = client.search_parts_by_number("45022-S9A-315")
      expect(result).to be_a(RockautoApi::Models::PartSearchResult)
      expect(result.search_term).to eq("45022-S9A-315")
    end
  end
end
```

- [ ] **Step 2: Run and record + replay verify**

- [ ] **Step 3: Commit**

---

### Task 6: Tools Endpoint Spec (VCR)

**Files:**
- Create: `spec/vcr/tools_spec.rb`

- [ ] **Step 1: Write tools spec**

```ruby
# frozen_string_literal: true

RSpec.describe "Tools endpoints", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#get_tool_categories" do
    it "returns tool categories" do
      result = client.get_tool_categories
      expect(result).to be_a(RockautoApi::Models::ToolCategories)
      expect(result.count).to be > 0
      expect(result.categories).to all be_a(RockautoApi::Models::ToolCategory)
    end
  end

  describe "#get_tools_by_category" do
    it "returns tools for a category" do
      categories = client.get_tool_categories
      first_cat = categories.categories.first
      result = client.get_tools_by_category(first_cat.href)
      expect(result).to be_a(RockautoApi::Models::ToolsResult)
      expect(result.count).to be >= 0
    end
  end
end
```

- [ ] **Step 2: Run and record + replay verify**

- [ ] **Step 3: Commit**

---

### Task 7: Orders Endpoint Spec (VCR)

**Files:**
- Create: `spec/vcr/orders_spec.rb`

- [ ] **Step 1: Write orders spec**

```ruby
# frozen_string_literal: true

RSpec.describe "Orders endpoints", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#lookup_order_status" do
    it "returns not found for invalid lookup" do
      result = client.lookup_order_status("test@example.com", "INVALID-ORDER")
      expect(result).to be_a(RockautoApi::Models::OrderStatusResult)
      expect(result.success).to be false
      expect(result.error).to be_a(RockautoApi::Models::OrderStatusError)
    end
  end

  describe "#request_order_list" do
    it "requests order list by email" do
      result = client.request_order_list(:email, "test@example.com")
      expect(result).to be true
    end
  end
end
```

- [ ] **Step 2: Run and record + replay verify**

- [ ] **Step 3: Commit**

---

### Task 8: Fitment Endpoint Spec (VCR)

**Files:**
- Create: `spec/vcr/fitment_spec.rb`

- [ ] **Step 1: Write fitment spec**

```ruby
# frozen_string_literal: true

RSpec.describe "Fitment endpoint", :vcr do
  subject(:client) { RockautoApi::Client.new }

  describe "#get_fitment_for_part" do
    it "returns default result for empty listing data" do
      result = client.get_fitment_for_part({})
      expect(result).to be_a(RockautoApi::Models::BuyersGuideResult)
      expect(result.count).to eq(0)
    end

    it "returns fitments for valid part data" do
      listing_data = {
        "groupindex" => "0",
        "car" => { "carcode" => 1477997, "parttype" => "12345", "partkey" => "67890" },
        "supplemental" => { "partnumber" => "45022-S9A-315", "catalogname" => "HONDA" },
        "optkey" => ""
      }
      result = client.get_fitment_for_part(listing_data)
      expect(result).to be_a(RockautoApi::Models::BuyersGuideResult)
    end
  end
end
```

- [ ] **Step 2: Run and record + replay verify**

- [ ] **Step 3: Commit**

---

### Task 9: Order Parser Unit Spec

**Files:**
- Create: `spec/unit/order_parser_spec.rb`
- Create: `spec/fixtures/html/order_status_found.html`
- Create: `spec/fixtures/html/order_status_not_found.html`

- [ ] **Step 1: Create fixture HTML for found order**

`spec/fixtures/html/order_status_found.html`:
```html
<html><body>
<table>
<tr><td>Order #</td><td>RA-123456</td></tr>
<tr><td>Date</td><td>01/15/2025</td></tr>
<tr><td>Status</td><td>Shipped</td></tr>
</table>
<table>
<tr><td>Part #</td><td>Description</td><td>Brand</td><td>Qty</td><td>Price</td></tr>
<tr><td>45022-S9A-315</td><td>Brake Pad Set</td><td>HONDA</td><td>1</td><td>$45.99</td></tr>
</table>
</body></html>
```

- [ ] **Step 2: Create fixture HTML for not found order**

```html
<html><body>
<p>No order found matching your criteria.</p>
</body></html>
```

- [ ] **Step 3: Write order parser unit spec**

```ruby
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
```

- [ ] **Step 4: Run unit tests**

Run: `bundle exec rspec spec/unit/order_parser_spec.rb --format documentation`
Expected: Passes

- [ ] **Step 5: Commit**

---

### Task 10: Part Extractor Unit Spec

**Files:**
- Create: `spec/unit/part_extractor_spec.rb`
- Create: `spec/fixtures/html/part_row.html`

- [ ] **Step 1: Create fixture HTML for part row**

`spec/fixtures/html/part_row.html`:
```html
<html><body>
<table>
<tr>
<td><img src="/images/parts/brake_pad.jpg"/></td>
<td><a href="/en/catalog/part">Brake Pad Set Ceramic</a></td>
<td>45022-S9A-315</td>
<td>HONDA</td>
<td>$45.99</td>
</tr>
</table>
</body></html>
```

- [ ] **Step 2: Write part extractor unit spec**

```ruby
# frozen_string_literal: true

RSpec.describe RockautoApi::Parsers::PartExtractor, :unit do
  describe ".extract_from_row" do
    it "extracts part info from a table row" do
      html = File.read("spec/fixtures/html/part_row.html")
      doc = Nokogiri::HTML(html)
      row = doc.at_css("tr")
      result = described_class.extract_from_row(row)
      expect(result).to be_a(RockautoApi::Models::PartInfo)
      expect(result.part_number).to eq("45022-S9A-315")
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
```

- [ ] **Step 3: Run**

Run: `bundle exec rspec spec/unit/part_extractor_spec.rb --format documentation`
Expected: Passes

- [ ] **Step 4: Commit**

---

### Task 11: Configuration Unit Spec

**Files:**
- Create: `spec/rockauto_api/configuration_spec.rb`

- [ ] **Step 1: Write configuration spec**

```ruby
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
```

- [ ] **Step 2: Run**

Run: `bundle exec rspec spec/rockauto_api/configuration_spec.rb --format documentation`
Expected: Passes

- [ ] **Step 3: Commit**

---

### Task 12: Final Suite Verification

- [ ] **Step 1: Run full suite**

Run: `bundle exec rspec --format documentation`
Expected: All tests pass

- [ ] **Step 2: Verify cassettes are recorded**

Run: `ls spec/cassettes/*.yml | wc -l`
Expected: Multiple cassette files present

- [ ] **Step 3: Run with network disabled to verify replay**

Run: `VCR_OFF=true bundle exec rspec --format documentation` or just run normally since VCR hooks into WebMock
Expected: All tests pass using only cassettes
