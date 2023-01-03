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

It has three main methods:

- initiate_transaction(amount, currencyCode, reasonForPayment): This method initiates a transaction with the specified amount, currency code, and reason for payment. It returns a Response object with a reference number, poll URL, and redirect URL.

- make_seamless_payment(amount, currencyCode, reference, reasonForPayment, customerEmail, customerPhone, customerName, paymentMethodRequiredFields): This method makes a seamless payment with the specified parameters. It returns a Response object with a reference number, transaction ID, and payment URL.

- get_payment_method_code(currency_code): This method returns the payment method code for the specified currency code.

To use the gem, you will need to require it and create a new Pesepay object with your integration key, encryption key, return URL, and result URL. You can then call any of the above methods on the object to make payments or retrieve payment information.

Here is an example of how you might use the Pesepay gem in your code:

```ruby
require 'pesepay'

# Create a new Pesepay object with your integration key, encryption key, return URL, and result URL
payment = Pesepay::Pesepay.new('INTEGRATION_KEY', 'ENCRYPTION_KEY', 'https://www.example.com/return', 'https://www.example.com/result')

# Initiate a transaction for $100 with the currency code "USD" and the reason "Online purchase"
response = payment.initiate_transaction(100, 'USD', 'Online purchase')

if response.success
  # Transaction was successful, so you can redirect the user to the redirect URL
  poll_url = response.pollUrl
  redirect_to response.redirectUrl
else
  # There was an error, so you can display the error message to the user
  puts response.message
end

# Make a seamless payment for $50 with the currency code "USD", reference number "123456", 
# reason "Subscription payment", customer email "customer@example.com", 
# customer phone "1234567890", customer name "John Doe", and payment method required fields 
# "cardNumber" and "expiryDate"
response = payment.make_seamless_payment(50, 'USD', '123456', 'Subscription payment', 'customer@example.com', '1234567890', 'John Doe', {"creditCardExpiryDate": "03/23", "creditCardNumber": "1231231231231234", "creditCardSecurityNumber": "000"})
# if paying using ecocash
response = payment.make_seamless_payment(50, 'USD', '123456', 'Subscription payment', 'customer@example.com', '1234567890', 'John Doe', {'customerPhoneNumber': '0777777777'})
if response.success
  # Payment was successful, so you can save poll_url and referenceNumber (used to check the status of a transaction)
  reference_number = response->referenceNumber;
  poll_url = response->pollUrl;
else
  # There was an error, so you can display the error message to the user
  puts response.message
end

# Get the payment method code for the currency code "USD"
payment_method_code = payment.get_payment_method_code('USD')

puts payment_method_code

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gitnyasha/pesepay. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/gitnyasha/pesepay/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pesepay project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/gitnyasha/pesepay/blob/master/CODE_OF_CONDUCT.md).
