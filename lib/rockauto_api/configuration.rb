# frozen_string_literal: true

module RockautoApi
  class Configuration
    attr_accessor :default_mobile, :cache, :request_timeout, :user_agent, :credentials

    def initialize
      @default_mobile = true
      @cache = nil
      @request_timeout = 30
      @user_agent = nil
      @credentials = nil
    end

    def email
      credentials&.fetch(:email, nil)
    end

    def password
      credentials&.fetch(:password, nil)
    end
  end
end
