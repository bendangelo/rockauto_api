# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri]
  }
  config.configure_rspec_metadata!
  config.ignore_localhost = true

  config.filter_sensitive_data("<SESSION_COOKIE>") do |interaction|
    set_cookie = interaction.response.headers["Set-Cookie"]
    set_cookie&.first.to_s
  end

  config.filter_sensitive_data("<COOKIE_HEADER>") do |interaction|
    cookie = interaction.request.headers["Cookie"]
    cookie&.first.to_s
  end

  # removed for now
  TEST_EMAIL = ""
  TEST_PASSWORD = ''

  config.filter_sensitive_data("<TEST_EMAIL>") { TEST_EMAIL }
  config.filter_sensitive_data("<TEST_PASSWORD>") { TEST_PASSWORD }
  config.filter_sensitive_data("<TEST_EMAIL_ENCODED>") { CGI.escape(TEST_EMAIL) }
  config.filter_sensitive_data("<TEST_PASSWORD_ENCODED>") { CGI.escape(TEST_PASSWORD) }

  config.before_record do |interaction|
    body = interaction.response.body
    if body.encoding == Encoding::ASCII_8BIT
      cleaned = body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      interaction.response.body = cleaned
    end
  end
end

RSpec.configure do |config|
  config.around(:each, :vcr) do |example|
    name = example.metadata[:cassette] ||
           example.metadata[:full_description].gsub(/[^A-Za-z0-9]+/, "_").gsub(/_+$/, "")
    VCR.use_cassette(name, record: :new_episodes) do
      example.run
    end
  end
end
