# frozen_string_literal: true

require "faraday"
require "faraday-cookie_jar"
require "nokogiri"
require "dry-types"
require "dry-struct"
require "json"
require "cgi"

require_relative "rockauto_api/version"
require_relative "rockauto_api/configuration"
require_relative "rockauto_api/errors"
require_relative "rockauto_api/cache"
require_relative "rockauto_api/models/vehicle"
require_relative "rockauto_api/models/fitment"
require_relative "rockauto_api/models/part"
require_relative "rockauto_api/models/order"
require_relative "rockauto_api/models/account"
require_relative "rockauto_api/models/tool"
require_relative "rockauto_api/parsers/html_helpers"
require_relative "rockauto_api/parsers/part_extractor"
require_relative "rockauto_api/parsers/fitment_parser"
require_relative "rockauto_api/parsers/order_parser"
require_relative "rockauto_api/endpoints/vehicles"
require_relative "rockauto_api/endpoints/part_categories"
require_relative "rockauto_api/endpoints/part_search"
require_relative "rockauto_api/endpoints/fitment"
require_relative "rockauto_api/endpoints/tools"
require_relative "rockauto_api/endpoints/orders"
require_relative "rockauto_api/endpoints/account"
require_relative "rockauto_api/client"
require_relative "rockauto_api/railtie" if defined?(Rails)

module RockautoApi
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
    end
  end
end
