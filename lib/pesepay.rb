# frozen_string_literal: true

require_relative "pesepay/version"
require "cgi"
require "digest"
require "uri"
require "net/http"
require "openssl"
require "base64"
require "json"

module Pesepay
  class Pesepay
    attr_accessor :result_url, :return_url

    def initialize(integration_key, encryption_key)
      @integration_key = integration_key
      @encryption_key = encryption_key
    end

    def create_transaction(amount, currency_code, reason_for_payment, reference)
      Transaction.new(amount, currency_code, reason_for_payment, reference)
    end

    def create_seamless_transaction(currency_code, payment_method_code, customer_email = nil, customer_phone = nil, customer_name = nil)
      Payment.new(currency_code, payment_method_code, customer_email, customer_phone, customer_name)
    end

    def initiate_transaction(transaction)
      response = create_transaction_request(transaction)
      process_response(response)
    end

    def make_seamless_payment(payment, reason_for_payment, amount, payment_method_required_fields, reference = nil)
      response = create_seamless_payment_request(payment, reason_for_payment, amount, payment_method_required_fields, reference)
      process_response(response)
    end

    def get_payment_method_code(currency_code)
      response = get_payment_method_code_request(currency_code)
      process_get_code_method(response)
    end

    def poll_transaction(poll_url)
      url = URI(poll_url)

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url)
      request["Authorization"] = @integration_key
      request["Content-Type"] = "application/json"
      response = http.request(request)

      process_poll_response(response)
    end

    def check_payment(reference_number)
      url = "https://api.pesepay.com/api/payments-engine/v1/payments/check-payment?reference_number=#{reference_number}"
      poll_transaction(url)
    end

    private

    def create_transaction_request(transaction)
      data = build_transaction_data(transaction)

      url = URI("https://api.pesepay.com/api/payments-engine/v1/payments/initiate")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(url)
      request["Authorization"] = @integration_key
      request["Content-Type"] = "application/json"
      request.body = { payload: data }.to_json
      http.request(request)
    end

    def create_seamless_payment_request(payment, reason_for_payment, amount, payment_method_required_fields, reference)
      data = build_seamless_payment_data(payment, reason_for_payment, amount, payment_method_required_fields, reference)

      url = URI("https://api.pesepay.com/api/payments-engine/v2/payments/make-payment")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(url)
      request["Authorization"] = @integration_key
      request["Content-Type"] = "application/json"
      request.body = { payload: data }.to_json
      http.request(request)
    end

    def get_payment_method_code_request(currency_code)
      url = URI("https://api.pesepay.com/api/payments-engine/v1/payment-methods/for-currency?currencyCode=#{currency_code}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url)
      http.request(request)
    end

    def process_get_code_method(response)
      if response.code == "200"
        response_body = JSON.parse(response.body)
        payment_method_code = response_body[0]["code"]
        return payment_method_code
      else
        Response.new(false, message: "Unable to get payment method code")
      end
    end

    def process_response(response)
      if response.code == "200"
        response_body = JSON.parse(response.body.gsub("'", '"'))
        inner_payload = response_body["payload"]
        raw_response = decrypt(inner_payload, @encryption_key)
        json_string = JSON.parse(raw_response)
        ref_no = json_string["reference_number"]
        poll_url = json_string["poll_url"]
        redirect_url = json_string["redirect_url"]
        Response.new(true, reference_number: ref_no, poll_url: poll_url, redirect_url: redirect_url, json_string: json_string)
      else
        message = JSON.parse(response.body)["message"]
        Response.new(false, message: message)
      end
    end

    def process_poll_response(response)
      if response.code == "200"
        response_body = JSON.parse(response.body)
        inner_payload = response_body["payload"]
        raw_response = decrypt(inner_payload)
        json_string = JSON.parse(raw_response)
        reference_number = json_string["reference_number"]
        poll_url = json_string["poll_url"]
        paid = json_string["transactionStatus"] == "SUCCESS"

        StatusResponse.new(reference_number, poll_url, paid, json_string)
      else
        message = JSON.parse(response.body)["message"]
        StatusResponse.new(nil, nil, false, message)
      end
    end

    def build_transaction_data(transaction)
      payload = {
        "amountDetails": {
          "amount": transaction.amount,
          "currencyCode": transaction.currency_code,
        },
        "reasonForPayment": transaction.reason_for_payment,
        "resultUrl": @result_url,
        "returnUrl": @return_url,
        "merchantReference": transaction.reference,
      }

      encrypted = encrypt(payload.to_json, @encryption_key)
      encrypted
    end

    def build_seamless_payment_data(payment, reason_for_payment, amount, payment_method_required_fields, reference)
      payload = {
        "amountDetails": {
          "amount": amount,
          "currencyCode": payment.currency_code,
        },
        "merchantReference": reference,
        "reasonForPayment": reason_for_payment,
        "resultUrl": @result_url,
        "returnUrl": @return_url,
        "paymentMethodCode": payment.payment_method_code,
        "customer": {
          "email": payment.customer_email,
          "phoneNumber": payment.customer_phone,
          "name": payment.customer_name,
        },
        "paymentMethodRequiredFields": payment_method_required_fields,
      }

      encrypted = encrypt(payload.to_json, @encryption_key)
      encrypted
    end

    def encrypt(payload, key)
      init_vector = key[0, 16]
      cryptor = OpenSSL::Cipher::AES.new(256, :CBC)
      cryptor.encrypt
      cryptor.key = key
      cryptor.iv = init_vector
      ciphertext = cryptor.update(pad(payload)) + cryptor.final
      Base64.strict_encode64(ciphertext)
    end

    def decrypt(payload, key)
      ciphertext = Base64.strict_decode64(payload)
      init_vector = key[0, 16]
      cryptor = OpenSSL::Cipher::AES.new(256, :CBC)
      cryptor.decrypt
      cryptor.key = key
      cryptor.iv = init_vector
      plaintext = cryptor.update(ciphertext) + cryptor.final
      plaintext
    end

    def pad(input)
      padding_length = 16 - (input.length % 16)
      input + (padding_length.chr * padding_length)
    end
  end

  class Response
    attr_reader :success, :reference_number, :poll_url, :redirect_url, :message, :raw_data

    def initialize(success, reference_number: nil, poll_url: nil, redirect_url: nil, message: nil, json_string: nil)
      @success = success
      @reference_number = reference_number
      @poll_url = poll_url
      @redirect_url = redirect_url
      @message = message
      @raw_data = json_string
    end

    
  end

  class StatusResponse
    attr_reader :reference_number, :poll_url, :paid, :raw_data

    def initialize(reference_number: nil, poll_url: nil, paid: false, json_string: nil)
      @paid = paid
      @reference_number = reference_number
      @poll_url = poll_url
      @raw_data = json_string
    end
  end

  class Transaction
    attr_accessor :amount, :currency_code, :reason_for_payment, :reference

    def initialize(amount, currency_code, reason_for_payment, reference)
      @amount = amount
      @currency_code = currency_code
      @reason_for_payment = reason_for_payment
      @reference = reference
    end
  end

  class Payment
    attr_accessor :currency_code, :payment_method_code, :customer_email, :customer_phone, :customer_name

    def initialize(currency_code, payment_method_code, customer_email = nil, customer_phone = nil, customer_name = nil)
      @currency_code = currency_code
      @payment_method_code = payment_method_code
      @customer_email = customer_email
      @customer_phone = customer_phone
      @customer_name = customer_name
    end
  end
end
