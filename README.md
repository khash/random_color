# RandomColor

RandomColor is a Ruby port of David Merfield's Random Color JS library (https://github.com/davidmerfield/randomColor). All options are the same as the JS library and the same format.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'random_color'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install random_color

## Usage

```ruby
g = ::RandomColor::Generator.new
g.generate
```

If you need to pass in any options:

```ruby
g.generate(hue: 'red', count: 10)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/khash/random_color.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
