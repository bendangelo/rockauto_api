# frozen_string_literal: true

module RockautoApi
  class Client
    CATALOG_API_URL = "https://www.rockauto.com/catalog/catalogapi.php"
    PARTSEARCH_URL = "https://www.rockauto.com/en/partsearch/"
    ORDERSTATUS_URL = "https://www.rockauto.com/orderstatus/"
    BASE_URL = "https://www.rockauto.com"

    MOBILE_HEADERS = {
      "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language" => "en-US,en;q=0.9",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Dest" => "document"
    }.freeze

    DESKTOP_HEADERS = {
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "Accept-Language" => "en-US,en;q=0.9",
      "Sec-Ch-Ua" => '"Chromium";v="139", "Not;A=Brand";v="99"',
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Dest" => "document"
    }.freeze

    INITIAL_COOKIES = {
      "idlist" => "0",
      "mkt_US" => "true",
      "mkt_CA" => "false",
      "mkt_MX" => "false",
      "year_2005" => "true",
      "ck" => "1"
    }.freeze

    attr_reader :cache, :authenticated

    def initialize(mobile: nil, cache: nil)
      mobile = RockautoApi.configuration&.default_mobile if mobile.nil?
      headers = mobile ? MOBILE_HEADERS : DESKTOP_HEADERS

      @conn = Faraday.new(url: BASE_URL) do |f|
        f.request :url_encoded
        f.use :cookie_jar
        f.adapter Faraday.default_adapter
        f.options.timeout = RockautoApi.configuration&.request_timeout || 30
        headers.each { |k, v| f.headers[k] = v }
      end

      set_initial_cookies
      @cache = cache || RockautoApi.configuration&.cache || RockautoApi::Cache.new
      @session_initialized = false
      @nck_token = nil
      @jnck_token = nil
      @authenticated = false
    end

    def set_initial_cookies
      INITIAL_COOKIES.each do |name, value|
        @conn.headers["Cookie"] = "#{@conn.headers['Cookie']}; #{name}=#{value}" unless @conn.headers["Cookie"].to_s.include?("#{name}=")
      end
    end

    def init_session!
      return if @session_initialized

      resp = @conn.get("/")
      @nck_token = Parsers::HtmlHelpers.extract_javascript_variable(resp.body, "_nck")
      @jnck_token = @nck_token ? CGI.escape(@nck_token) : nil
      @session_initialized = true
    end

    def call_catalog_api(function, payload)
      init_session!

      data = {
        "func" => function,
        "payload" => payload.is_a?(String) ? payload : payload.to_json,
        "api_json_request" => "1",
        "sctchecked" => "1",
        "scbeenloaded" => "false",
        "curCartGroupID" => ""
      }
      data["_jnck"] = @jnck_token if @jnck_token

      resp = Faraday.new(url: BASE_URL) do |f|
        f.request :url_encoded
        f.use :cookie_jar
        f.adapter Faraday.default_adapter
        f.options.timeout = RockautoApi.configuration&.request_timeout || 30
        f.headers["X-Requested-With"] = "XMLHttpRequest"
        f.headers["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8"
        f.headers["User-Agent"] = MOBILE_HEADERS["User-Agent"]
        f.headers["Referer"] = "#{BASE_URL}/"
        @conn.headers["Cookie"].to_s.split(";").each do |cookie|
          name, val = cookie.strip.split("=", 2)
          f.headers["Cookie"] = "#{f.headers['Cookie']}; #{name}=#{val}" if name && val
        end
      end.post("catalog/catalogapi.php", data)

      JSON.parse(resp.body)
    rescue Faraday::Error => e
      raise NetworkError, "API request failed: #{e.message}"
    end

    def post_with_csrf(url, form_data)
      init_session!
      page_resp = @conn.get(url)
      nck = Parsers::HtmlHelpers.extract_csrf_token(page_resp.body)
      form_data["_nck"] = nck if nck
      resp = @conn.post(url, form_data)
      resp.body
    end

    def simulate_navigation_context(make: nil, year: nil)
      return unless make || year

      if make
        @conn.headers["Referer"] = "#{BASE_URL}/en/catalog/"
      end

      if year
        @conn.headers["Cookie"] = "#{@conn.headers['Cookie']}; year_#{year}=true"
      end

      if make
        payload = {
          "jsn" => {
            "make" => make,
            "nodetype" => "make",
            "loaded" => false,
            "expand_after_load" => true,
            "fetching" => true,
            "max_group_index" => 363,
            "mkt_US" => true,
            "mkt_CA" => false,
            "mkt_MX" => false
          }
        }
        call_catalog_api("navnode_fetch", payload)
      end
    end

    def get(path)
      init_session!
      resp = @conn.get(path)
      resp.body
    rescue Faraday::Error => e
      raise NetworkError, "GET #{path} failed: #{e.message}"
    end

    def post(path, body = nil)
      init_session!
      resp = @conn.post(path, body)
      resp.body
    rescue Faraday::Error => e
      raise NetworkError, "POST #{path} failed: #{e.message}"
    end

    include Endpoints::Vehicles
    include Endpoints::PartCategories
    include Endpoints::PartSearch
    include Endpoints::Fitment
    include Endpoints::Tools
    include Endpoints::Orders
    include Endpoints::Account
  end
end
