# frozen_string_literal: true

module RockautoApi
  class Railtie < ::Rails::Railtie
    config.rockauto_api = RockautoApi::Configuration.new

    initializer "rockauto_api.configure" do |app|
      RockautoApi.configure do |config|
        config.cache = Rails.cache
      end
    end

    generators do
      require "rails/generators"
    end
  end
end
