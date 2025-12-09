# Pesepay

Pesepay is a payment gateway ruby gem that allows you to make and manage payments online.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pesepay'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pesepay

## Usage

- initiate_transaction is a method in the Pesepay class that allows merchants to initiate a payment transaction. When called, it sends a request to the Pesepay API with the transaction details, such as the amount, currency, description, and reference number. If the request is successful, the method returns a Response object containing a reference number, poll URL, and redirect URL. The reference number can be used for tracking purposes, while the poll URL and redirect URL are used for further processing and redirecting the customer to complete the payment.

- make_seamless_payment is another method in the Pesepay class, designed for seamless payment processing. It enables merchants to process credit card payments without redirecting customers to the Pesepay platform. This method also sends a request to the Pesepay API with the necessary payment details, and if the request is successful, it returns a Response object with a reference number, poll URL, and redirect URL. These URLs are crucial for handling the payment process and communicating the status back to the merchant's platform. Additionally, this method requires specific payment method details, like credit card information, to perform the seamless payment.

- get_payment_method_code(currency_code): This method returns the payment method code for the specified currency code.

Here is an example of how you might use the Pesepay gem in your code:

```ruby
require 'pesepay'

# Create a new Pesepay object with your integration key and encryption key

pesepay = Pesepay::Pesepay.new('INTEGRATION_KEY', 'ENCRYPTION_KEY')

```

### To redirect to pesepay page and make paymnets

```ruby

# Set the return URL and result URL for handling the transaction status

pesepay.result_url = "http://example.com/gateway/result"
pesepay.return_url = "http://example.com/gateway/return"

# Create a transaction for $100 with the currency code "USD" and the reason "Pizza"

transaction = pesepay.create_transaction(100, "USD", "Pizza", 11.99)

# Initiate the transaction and get the response from the API

response = pesepay.initiate_transaction(transaction)

if response.success

# Transaction initiation was successful, so redirect the user to the provided redirect URL

poll_url = response.pollUrl
redirect_to response.redirectUrl
else

# There was an error, so display the error message to the user

puts response.message
end
```

### To Make a seamless payment using credit card for $50 with the currency code "USD"

```ruby
payment = pesepay.create_seamless_transaction("USD", "PZW204", "customer@example.com", "555-555-1212", "John Smith")

# visa
payment_method_required_fields = {
"creditCardExpiryDate": "09/23",
"creditCardNumber": "4867960000005461",
"creditCardSecurityNumber": "608"
}

response = pesepay.make_seamless_payment(payment, "Test payment", 100, payment_method_required_fields, "merchant_ref")

if response.success

# Payment was successful, so save the reference number and poll URL for checking the transaction status
reference_number = response.reference_number
poll_url = response.poll_url

# whole response data
data = response.raw_data
else

# There was an error, so display the error message to the user

puts response.message
end

# If paying using mobile money, provide the required payment details

payment = pesepay.create_seamless_transaction("USD", "PZW211", "customer@example.com", "555-555-1212", "John Smith")

# direct mobile payments e.g ecocash, innbucs
payment_method_required_fields = {
'customerPhoneNumber': '0777777777'
}

response = pesepay.make_seamless_payment(payment, "Test payment", 100.00, payment_method_required_fields, "merchant_ref")

if response.success

# Payment was successful, so save the reference number and poll URL for checking the transaction status

reference_number = response.referenceNumber
poll_url = response.pollUrl
# whole response data
data = response.raw_data

else

# There was an error, so display the error message to the user

puts response.message
end

# Get the payment method code for the currency code "USD"

payment_method_code = payment.get_payment_method_code('USD')

puts payment_method_code


```

Make sure to replace 'INTEGRATION_KEY' and 'ENCRYPTION_KEY' with your actual Pesepay integration and encryption keys. Additionally, adjust the URLs and payment details accordingly to match your application's requirements.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gitnyasha/pesepay. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/gitnyasha/pesepay/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pesepay project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/gitnyasha/pesepay/blob/master/CODE_OF_CONDUCT.md).
