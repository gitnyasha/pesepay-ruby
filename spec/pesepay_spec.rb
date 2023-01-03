# frozen_string_literal: true

RSpec.describe Pesepay do
  # create a new instance of Pesepay with keys from the .env file
  pesepay = Pesepay::Pesepay.new(ENV['inteKey'],ENV['encryptKey'], "http://localhost:3000", "http://localhost:3000")

  describe "#initiate_transaction" do
    context "when the request is successful" do
      it "returns a Response object with a reference number, poll URL, and redirect URL" do
        response = pesepay.initiate_transaction(100, "USD", "Test payment")

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
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(double(code: "400", read_body: { "message" => "Error message" }))

        response = pesepay.initiate_transaction(100, "USD", "Test payment")

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
        payment_method_required_fields = { "creditCardExpiryDate": "03/23", "creditCardNumber": "486 796 000 000 546 1", "creditCardSecurityNumber": "608"}
        response = pesepay.make_seamless_payment(100, "USD", "123456", "Test payment", "customer@example.com", "555-555-1212", "John Smith", payment_method_required_fields)

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
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(double(code: "400", read_body: { "message" => "Error message" }))

        payment_method_required_fields = { "creditCardExpiryDate": "03/23", "creditCardNumber": "486 796 000 000 546 1", "creditCardSecurityNumber": "608"}
        response = pesepay.make_seamless_payment(100, "USD", "123456", "Test payment", "customer@example.com", "555-555-1212", "John Smith", payment_method_required_fields)

        # check if the response status is false
        expect(response.success).to be false
        # check if the response has an error message
        expect(response.message).to be_a(String)
      end
    end
  end
end
