# frozen_string_literal: true

require_relative "pesepay/version"
require "cgi"
require "digest"
require "uri"
require "net/http"

module Pesepay
  class Error < StandardError; end

  class Pesepay
    @integration_key = "YOUR_INTEGRATION_KEY"
    @integration_secret = "YOUR_INTEGRATION_SECRET"
    @return_url = "https://my.return.url.com"
    @result_url = "https://my.resulturl.com"

    def initialize(integration_key, integration_secret)
      @integration_key = integration_key
      @integration_secret = integration_secret
    end

    def initiate_transaction(payment)
      data = build(payment)

      url = URI("https://api.pesepay.com/api/payments-engine/v1/payments/initiate")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(url)
      request["authorization"] = "#{@integration_key}"
      request["content-type"] = "application/json"
      request.body = data

      response = http.request(request)
      response.read_body
    end

    def build(payment)
      payload = {
        "amountDetails": {
          "amount": 100,
          "currencyCode": "ZWD",
        },
        "reasonForPayment": "Online payment for Camera",
        "resultUrl": @result_url,
        "returnUrl": @return_url,
      }

      joined = payload.values.join
      add_key = joined += @integration_secret
      payload["hash"] = encryptPayload(add_key)
      return URI.encode_www_form(payload)
    end

    def encryptPayload(payload)
      Digest::SHA2.new(512).hexdigest(payload).upcase
    end
  end
end
