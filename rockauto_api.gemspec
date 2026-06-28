# frozen_string_literal: true

require_relative "lib/rockauto_api/version"

Gem::Specification.new do |spec|
  spec.name = "rockauto_api"
  spec.version = RockautoApi::VERSION
  spec.authors = ["Ben D'Angelo"]
  spec.summary = "Comprehensive Ruby API client for RockAuto.com"
  spec.description = "Browse vehicle catalogs, search parts by number, get vehicle fitments, track orders, and manage RockAuto accounts. Designed for Rails integration."
  spec.homepage = "https://github.com/bendangelo/rockauto_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/master/CHANGELOG.md"
  }

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-cookie_jar"
  spec.add_dependency "nokogiri", "~> 1.15"
  spec.add_dependency "dry-types", "~> 1.7"
  spec.add_dependency "dry-struct", "~> 1.6"
end
