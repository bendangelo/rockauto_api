# frozen_string_literal: true

module RockautoApi
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class CaptchaError < Error; end
  class NetworkError < Error; end
  class ParseError < Error; end
  class NotFoundError < Error; end
end
