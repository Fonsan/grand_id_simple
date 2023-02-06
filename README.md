# GrandIdSimple

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/grand_id_simple`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add grand_id_simple

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install grand_id_simple

## Usage


```bash
GRAND_ID_API_KEY='123' GRAND_ID_SERVICE_KEY='467' ruby some_app.rb
```

```ruby
api_key, service_key = ENV.values_at('GRAND_ID_API_KEY', 'GRAND_ID_SERVICE_KEY')

grand_id_simple = GrandIdSimple.new(api_key, service_key)

grand_id_simple.federated_login(your_callback_url)
# or if you know the personal number and would like to extend the courtesy of not having to scan qr code or manually fill
login = grand_id_simple.federated_login(your_callback_url, personal_number: '198801010101')
# => #<struct GrandIdSimple::Login session_id="123", redirect_url="https://grandid.se/redirect....">
# redirect your user
redirect_to(login.redirect_url)

# Then when you receive the callback:

person = grand_id_simple.get_session(params[:grandidsession])
# => #<struct GrandIdSimple::Person personal_number="198801010101", name="Greta Musk", given_name="Greta", surname="Musk", ip_address=...>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Fonsan/grand_id_simple. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/Fonsan/grand_id_simple/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the GrandIdSimple project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Fonsan/grand_id_simple/blob/main/CODE_OF_CONDUCT.md).
