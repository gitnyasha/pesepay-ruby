# frozen_string_literal: true

RSpec.describe Pesepay do
  # create a new instance of Pesepay
  pesepay = Pesepay::Pesepay.new("integrationkey", "secretkey")
  it "has a version number" do
    expect(Pesepay::VERSION).not_to be nil
  end

  it "return a response after initiating a request" do
    response = pesepay.initiate_transaction(pesepay)
    expect(response).not_to be nil
  end

  it "encrypts json string of the transaction details" do
    response = pesepay.build(pesepay)
    expect(response).not_to be nil
  end
end
