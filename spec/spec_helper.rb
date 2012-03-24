$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

if ENV["COVERAGE"]
  require 'simplecov'

  SimpleCov.start {
    add_filter "/vendor/"
    add_filter "/spec/"
  }
end

require 'rspec'
require 'rack/test'
require 'omniauth'
require 'omniauth-rtm'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.extend  OmniAuth::Test::StrategyMacros, :type => :strategy

  config.mock_with :rspec
  config.fail_fast
end
