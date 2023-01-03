# frozen_string_literal: true

require_relative "pesepay/version"
require "cgi"
require "digest"
require "uri"
require "net/http"
require "openssl"
require "base64"
require 'json'

module Pesepay
  class Pesepay
    def initialize(integration_key, encryption_key, return_url, result_url)
      @integration_key = integration_key
      @encryption_key = encryption_key
      @return_url = return_url
      @result_url = result_url
    end

    def initiate_transaction(amount, currencyCode, reasonForPayment)
      response = create_transaction(self, amount, currencyCode, reasonForPayment)
    end

    def make_seamless_payment(amount, currencyCode, reference, reasonForPayment, customerEmail, customerPhone, customerName, paymentMethodRequiredFields)
      response = create_seamless_transaction(self, amount, currencyCode, reference, reasonForPayment, customerEmail, customerPhone, customerName, paymentMethodRequiredFields)
    end

    def get_payment_method_code(currency_code)
      url = URI("https://api.pesepay.com/api/payments-engine/v1/payment-methods/for-currency?currencyCode=#{currency_code}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url)
      response = http.request(request)

      if response.code == "200"
        # parse the response body and extract the payment method code
        response_body = JSON.parse(response.body)
        payment_method_code = response_body[0]['code']
        return payment_method_code
      else
        Response.new(false, message: "Unable to get payment method code")
      end
    end

    def create_transaction(payment, amount, currencyCode, reasonForPayment)
      data = build_transaction(payment, amount, currencyCode, reasonForPayment)

      url = URI("https://api.pesepay.com/api/payments-engine/v1/payments/initiate")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(url)
      request["Authorization"] = @integration_key
      request["Content-Type"] = 'application/json'
      request.body = { payload: data }.to_json
      response = http.request(request)
      if response.code == "200"
        response_body = response.read_body.gsub("'", '"')
        json = JSON.parse(response_body)
        inner_payload = json['payload']
        raw_response = decrypt(inner_payload, @encryption_key)
        json_string = JSON.parse(raw_response)
        ref_no = json_string['referenceNumber']
        poll_url = json_string['pollUrl']
        redirect_url = json_string['redirectUrl']
        Response.new(true, referenceNumber: ref_no, pollUrl: poll_url, redirectUrl: redirect_url)
      else
        message = response.read_body['message']
        Response.new(false, message: message)
      end
    end

    def create_seamless_transaction(payment, amount, currencyCode, reference, reasonForPayment, customerEmail, customerPhone, customerName, paymentMethodRequiredFields)
      payment_method_code = get_payment_method_code(currencyCode)
      data = build_payment(payment, amount, currencyCode, reference, reasonForPayment, payment_method_code, customerEmail, customerPhone, customerName, paymentMethodRequiredFields)

      url = URI("https://api.pesepay.com/api/payments-engine/v2/payments/make-payment")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(url)
      request["Authorization"] = @integration_key
      request["Content-Type"] = 'application/json'
      request.body = { payload: data }.to_json
      response = http.request(request)
      response.read_body
      if response.code == "200"
        response_body = response.read_body.gsub("'", '"')
        json = JSON.parse(response_body)
        inner_payload = json['payload']
        raw_response = decrypt(inner_payload, @encryption_key)
        json_string = JSON.parse(raw_response)
        ref_no = json_string['referenceNumber']
        poll_url = json_string['pollUrl']
        redirect_url = json_string['redirectUrl']
        Response.new(true, referenceNumber: ref_no, pollUrl: poll_url, redirectUrl: redirect_url)
      else
        message = response.read_body['message']
        Response.new(false, message: message)
      end
    end

    def check_payment_status(referenceNumber)
      url = URI("https://api.pesepay.com/api/payments-engine/v1/payments/check-payment?refenceNumber=#{referenceNumber}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url)
      request["Authorization"] = @integration_key
      request["Content-Type"] = 'application/json'

      response = http.request(request)
      if response.code == "200"
        response_body = response.read_body.gsub("'", '"')
        json = JSON.parse(response_body)
        inner_payload = json['payload']
        return raw_response = decrypt(inner_payload, @encryption_key)
        json_string = JSON.parse(raw_response)
        ref_no = json_string['referenceNumber']
        status = json_string['transactionStatus']
        poll_url = json_string['pollUrl']
        redirect_url = json_string['redirectUrl']
        Response.new(true, nil, ref_no, poll_url, redirect_url, status == 'SUCCESS')
      else
        message = response.read_body['message']
        Response.new(false,  message: message)
      end
    end

    def build_transaction(payment, amount, currencyCode, reasonForPayment)
      payload = {
        "amountDetails": {
          "amount": amount,
          "currencyCode": currencyCode,
        },
        "reasonForPayment": reasonForPayment,
        "resultUrl": @result_url,
        "returnUrl": @return_url,
      }

      encrypted = encrypt(payload.to_json, @encryption_key)
      return encrypted
    end

    def build_payment(payment, amount, currencyCode, reference, reasonForPayment, paymentMethodCode, customerEmail, customerPhone, customerName, paymentMethodRequiredFields)
      payload = {
          "amountDetails": {
              "amount": amount,
              "currencyCode": currencyCode,
          },
          "merchantReference": reference,
          "reasonForPayment": reasonForPayment,
          "resultUrl": @result_url,
          "returnUrl": @return_url,
          "paymentMethodCode": paymentMethodCode,
          "customer": {
              "email": customerEmail,
              "phoneNumber": customerPhone,
              "name": customerName
          },
          "paymentMethodRequiredFields": paymentMethodRequiredFields
      }

      encrypted = encrypt(payload.to_json, @encryption_key)
      return encrypted
    end

   def encrypt(payload, key)
      init_vector = key[0, 16]
      cryptor = OpenSSL::Cipher::AES.new(256, :CBC)
      cryptor.encrypt
      cryptor.key = key
      cryptor.iv = init_vector
      ciphertext = cryptor.update(pad(payload)) + cryptor.final
      return Base64.strict_encode64(ciphertext)
    end

    def decrypt(payload, key)
      ciphertext = Base64.strict_decode64(payload)
      init_vector = key[0, 16]
      cryptor = OpenSSL::Cipher::AES.new(256, :CBC)
      cryptor.decrypt
      cryptor.key = key
      cryptor.iv = init_vector
      plaintext = cryptor.update(ciphertext) + cryptor.final
      return plaintext
    end

    def pad(input)
      padding_length = 16 - (input.length % 16)
      return input + (padding_length.chr * padding_length)
    end
  end

  class Response
    attr_reader :success, :referenceNumber, :pollUrl, :redirectUrl, :message

    def initialize(success, referenceNumber: nil, pollUrl: nil, redirectUrl: nil, message: nil)
      @success = success
      @referenceNumber = referenceNumber
      @pollUrl = pollUrl
      @redirectUrl = redirectUrl
      @message = message
    end
  end

end
