# frozen_string_literal: true

RSpec.describe Pesepay do
  pesepay = Pesepay::Pesepay.new("Integration_key", "encryption_key")
  pesepay.result_url = "http://example.com/gateway/return"
  pesepay.return_url = "http://example.com/gateway/return"

  describe "#initiate_transaction" do
    context "when the request is successful" do
      it "returns a Response object with a reference number, poll URL, and redirect URL" do
        transaction = pesepay.create_transaction(100, "USD", "Test payment", "1239353")
        response = pesepay.initiate_transaction(transaction)

        # check if the response status is true
        expect(response.success).to be true
        # check if the response has the expected reference number, poll URL, and redirect URL
        expect(response.referenceNumber).to be_a(String)
        expect(response.pollUrl).to be_a(String)
        expect(response.redirectUrl).to be_a(String)
      end
    end

    context "when the request fails" do
      it "returns a Response object with an error message" do
        # mock the HTTP request to return a failed response
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(double(code: "400", body: { "message" => "Error message" }.to_json))

        transaction = pesepay.create_transaction(100, "USD", "Test payment", "123456")
        response = pesepay.initiate_transaction(transaction)

        # check if the response status is false
        expect(response.success).to be false
        # check if the response has an error message
        expect(response.message).to be_a(String)
      end
    end
  end

  describe "#make_seamless_payment" do
    context "when the request is successful" do
      it "returns a Response object with a reference number, poll URL, and redirect URL" do
        payment = pesepay.create_seamless_transaction("USD", "PZW204", "customer@example.com", "555-555-1212", "John Smith")
        payment_method_required_fields = { "creditCardExpiryDate": "09/23", "creditCardNumber": "4867960000005461", "creditCardSecurityNumber": "608" }
        response = pesepay.make_seamless_payment(payment, "Test payment", 100, payment_method_required_fields, "123453234")

        # check if the response status is true
        expect(response.success).to be true
        # check if the response has the expected reference number, poll URL, and redirect URL
        expect(response.referenceNumber).to be_a(String)
        expect(response.pollUrl).to be_a(String)
      end
    end

    context "when the request fails" do
      it "returns a Response object with an error message" do
        # mock the HTTP request to return a failed response
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(double(code: "400", body: { "message" => "Error message" }.to_json))

        payment = pesepay.create_seamless_transaction("USD", "PZW204", "customer@example.com", "555-555-1212", "John Smith")
        payment_method_required_fields = { "creditCardExpiryDate": "03/23", "creditCardNumber": "486 796 000 000 546 1", "creditCardSecurityNumber": "608" }
        response = pesepay.make_seamless_payment(payment, "Test payment", 100, payment_method_required_fields, "123456")

        # check if the response status is false
        expect(response.success).to be false
        # check if the response has an error message
        expect(response.message).to be_a(String)
      end
    end
  end
end
