# Omniauth RTM Strategy

This gem provides a simple way to authenticate to [remember the milk](http://rememberthemilk.com) using [OmniAuth](http://github.com/intridea/omniauth/wiki).

## Usage

Add this line to your application's Gemfile:

```ruby
gem 'omniauth'
gem 'omniauth-rtm'
```

Then integrate the strategy into your middleware:

```ruby
use OmniAuth::Builder do
  provider :rtm, ENV['RTM_KEY'], ENV['RTM_SECRET']
end
```

In Rails, you'll want to add to the middleware stack:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :rtm, ENV['RTM_KEY'], ENV['RTM_SECRET']
end
```

## Auth Hash Schema

The following information is provided back to you for this provider:

```ruby
{
  uid: '12345',
  info: {
    nickname: 'name',
    name: 'Full Name'
  },
  credentials: {
    token: 'thetoken' # can be used to auth to the API
  }
}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
