# RockautoApi

An unofficial Ruby API client for [RockAuto.com](https://www.rockauto.com). Browse vehicle catalogs, search parts by number, look up fitments, check order status, and manage your RockAuto account.

**Disclaimer:** This gem is for **educational and research purposes only**. It is not affiliated with, endorsed by, or officially connected to RockAuto LLC. Automated scraping of RockAuto.com may violate their Terms of Service. Use responsibly and respect rate limits.

---

## Installation

Add to your Gemfile:

```ruby
gem "rockauto_api"
```

Then:

```
bundle install
```

Or install directly:

```
gem install rockauto_api
```

---

## Quick Start

```ruby
require "rockauto_api"

client = RockautoApi::Client.new

# Browse what RockAuto sells
makes = client.get_makes
makes.makes #=> ["ACURA", "AUDI", "BMW", ...]

years = client.get_years_for_make("AUDI")
years.years #=> [1980, 1981, ..., 2026]

models = client.get_models_for_make_year("AUDI", 2019)
models.models #=> ["A4", "A5", "A6", "A7", ...]

engines = client.get_engines_for_vehicle("AUDI", 2019, "A4")
engines.engines #=> [Engine(description: "2.0L L4 Turbocharged", carcode: "3443561"), ...]

# Get part categories for a vehicle
categories = client.get_part_categories("AUDI", 2019, "A4", "3443561")
categories.categories #=> [PartCategory(name: "Belt Drive"), ...]

# Get parts in a category
parts = client.get_parts_by_category("AUDI", 2019, "A4", "3443561", "Belt Drive")
parts.parts #=> [PartInfo, ...]
```

---

## All Endpoints

### Vehicle Catalog

Browse the vehicle catalog to find makes, years, models, and engines.

```ruby
# List all makes
makes = client.get_makes
makes.makes   #=> ["ACURA", "AUDI", "BMW", ...]
makes.count   #=> Integer

# List years for a make
years = client.get_years_for_make("ACURA")
years.make    #=> "ACURA"
years.years   #=> [1986, 1987, ..., 2026]
years.count   #=> Integer

# List models for a make and year
models = client.get_models_for_make_year("ACURA", 2020)
models.make   #=> "ACURA"
models.year   #=> 2020
models.models #=> ["MDX", "TLX", ...]
models.count  #=> Integer

# List engines for a specific vehicle
engines = client.get_engines_for_vehicle("ACURA", 2020, "MDX")
engines.make       #=> "ACURA"
engines.year       #=> 2020
engines.model      #=> "MDX"
engines.engines    #=> [Engine(description, carcode, href), ...]
engines.count      #=> Integer
```

### Part Categories

Get the part categories available for a specific vehicle, and parts within a category.

```ruby
# Get all part categories for a vehicle
categories = client.get_part_categories("ACURA", 2020, "MDX", "3444459")
categories.make       #=> "ACURA"
categories.year       #=> 2020
categories.model      #=> "MDX"
categories.carcode    #=> "3444459"
categories.categories #=> [PartCategory(name, group_name, href), ...]
categories.count      #=> Integer

# Get parts in a category
parts = client.get_parts_by_category("ACURA", 2020, "MDX", "3444459", "Brake & Wheel Hub")
parts.make       #=> "ACURA"
parts.year       #=> 2020
parts.model      #=> "MDX"
parts.carcode    #=> "3444459"
parts.category   #=> "Brake & Wheel Hub"
parts.parts      #=> [PartInfo, ...]
parts.count      #=> Integer
```

### Part Search

Search for parts by number, name, or browse available manufacturers, groups, and types.

```ruby
# Browse available manufacturers (cached for 24 hours)
manufacturers = client.get_manufacturers
manufacturers.manufacturers #=> [PartSearchOption(value, text), ...]
manufacturers.lookup("Bosch") #=> PartSearchOption(value: "128", text: "Bosch")

# Browse part groups (cached for 24 hours)
groups = client.get_part_groups
groups.part_groups #=> [PartSearchOption(value, text), ...]

# Browse part types (cached for 24 hours)
types = client.get_part_types
types.part_types #=> [PartSearchOption(value, text), ...]

# Search parts by number
results = client.search_parts_by_number("FG0326")
results.parts        #=> [PartInfo, ...]
results.count        #=> Integer
results.search_term  #=> "FG0326"
results.manufacturer #=> "All"
results.part_group   #=> "All"

# Search with filters
results = client.search_parts_by_number(
  "FG0326",
  manufacturer: "Bosch",
  part_group: "Brakes",
  part_type: "Pads"
)

# Include fitment data (triggers additional API call per part)
results = client.search_parts_by_number("FG0326", include_fitments: true)
results.parts.first.buyers_guide #=> BuyersGuideResult

# Look up what a part is called
results = client.what_is_part_called("brake pad")
results.results #=> [WhatIsPartCalledResult(main_category, subcategory, full_path), ...]
```

### Fitment / Buyers Guide

Get vehicle fitment information for a specific part.

```ruby
fitment = client.get_fitment_for_part(listing_data)
# listing_data comes from PartInfo#listing_data or can be constructed manually
fitment.part_number #=> "FG0326"
fitment.brand      #=> "Bosch"
fitment.fitments   #=> [FitmentInfo(year, make, model, engine, ...), ...]
fitment.count      #=> Integer
```

### Order Status

Look up order status and request order lists (no login required).

```ruby
# Look up an order by email and order number
result = client.lookup_order_status("you@example.com", "RA-123456")
result.success #=> true/false
result.order   #=> OrderStatus (if found)
result.error   #=> OrderStatusError (if not found)

# Order status details
order = result.order
order.order_number    #=> "RA-123456"
order.order_date      #=> "2024-01-15"
order.status          #=> "Shipped"
order.items           #=> [OrderItem(part_number, description, quantity, ...), ...]
order.billing         #=> BillingInfo(subtotal, shipping_cost, tax, total, ...)
order.shipping        #=> ShippingInfo(method, carrier, tracking_number, ...)
order.notes           #=> String
order.return_eligibility #=> String

# Request RockAuto to email you a list of your orders
client.request_order_list(:email, "you@example.com") #=> true

# Request via SMS
client.request_order_list(:sms, "+15551234567") #=> true
```

### Account (Authenticated)

Requires logging in with valid RockAuto credentials.

```ruby
# Configure credentials globally
RockautoApi.configure do |config|
  config.credentials = { email: "you@example.com", password: "your_password" }
end

# Or pass credentials per-session
client = RockautoApi::Client.new
client.login("you@example.com", "your_password")

# Check login status
client.authenticated? #=> true/false

# Get saved addresses
addresses = client.get_saved_addresses
addresses.addresses   #=> [SavedAddress(name, full_name, address_line1, city, state, ...), ...]
addresses.count       #=> Integer
addresses.has_default #=> true/false

# Get saved vehicles
vehicles = client.get_saved_vehicles
vehicles.vehicles #=> [SavedVehicle(year, make, model, engine, carcode, ...), ...]
vehicles.count    #=> Integer

# Get order history
history = client.get_order_history
history.orders       #=> [OrderHistoryItem(order_number, date, status, total, vehicle), ...]
history.count        #=> Integer
history.search_time  #=> "2026-06-28T..."

# Get full account activity (addresses + vehicles)
activity = client.get_account_activity
activity.saved_addresses  #=> SavedAddressesResult
activity.saved_vehicles   #=> SavedVehiclesResult

# Add an external order to your account
client.add_external_order("you@example.com", "RA-123456") #=> true

# Logout
client.logout #=> true
client.authenticated? #=> false
```

### Tools

Browse RockAuto's tool catalog.

```ruby
# Get tool categories
categories = client.get_tool_categories
categories.categories #=> [ToolCategory(name, group_name, href, level), ...]
categories.count      #=> Integer

# Get tools in a category
tools = client.get_tools_by_category("/en/tools/?parttype=260")
tools.tools       #=> [ToolInfo(name, part_number, brand, description, ...), ...]
tools.count       #=> Integer
tools.category    #=> "?parttype=260"
```

---

## Configuration

```ruby
RockautoApi.configure do |config|
  config.default_mobile  = true   # Use mobile site headers (slimmer HTML)
  config.request_timeout = 30     # HTTP timeout in seconds
  config.credentials     = { email: "me@example.com", password: "s3cret" }
  config.cache           = Rails.cache  # Use Rails cache for 24h/7d TTLs
end
```

---

## Rails Integration

The gem includes a Railtie that automatically hooks into `Rails.cache`. No extra setup needed:

```ruby
# Gemfile
gem "rockauto_api"

# config/initializers/rockauto_api.rb
RockautoApi.configure do |config|
  config.default_mobile = false
end

# app/models/part_lookup.rb
class PartLookup
  def search(query)
    client = RockautoApi::Client.new
    client.search_parts_by_number(query)
  end
end
```

---

## Error Handling

All errors inherit from `RockautoApi::Error`:

| Error Class | When It's Raised |
|---|---|
| `RockautoApi::AuthenticationError` | Calling authenticated methods without logging in |
| `RockautoApi::NetworkError` | HTTP request fails (timeout, connection error) |
| `RockautoApi::CaptchaError` | RockAuto returns a CAPTCHA challenge |
| `RockautoApi::ParseError` | Failed to parse HTML response |
| `RockautoApi::NotFoundError` | Resource not found |

Example:

```ruby
begin
  client.get_saved_addresses
rescue RockautoApi::AuthenticationError => e
  puts "Please login first: #{e.message}"
rescue RockautoApi::NetworkError => e
  puts "Network issue: #{e.message}"
end
```

---

## Development

```
git clone https://github.com/bendangelo/rockauto_api
cd rockauto_api
bin/setup
```

Run the test suite:

```
bundle exec rspec
```

Tests use [VCR](https://github.com/vcr/vcr) to record and replay HTTP interactions. To re-record cassettes with live data:

```
rm -rf spec/cassettes/
bundle exec rspec
```

New cassettes will be created recording real HTTP requests. Sensitive data (credentials, cookies) is automatically filtered.

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am "Add my feature"`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

Please include tests for any new functionality and ensure the full suite passes.

---

## License

Apache 2.0. See [LICENSE](LICENSE).

---

## Disclaimer

This software is provided for **educational and research purposes only**. It is not affiliated with, endorsed by, or officially connected to RockAuto LLC. Automated access to RockAuto.com may violate their Terms of Service. Users are solely responsible for ensuring their use complies with all applicable terms and laws. The authors assume no liability for any misuse.
