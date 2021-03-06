require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
end

RSpec.configure { |c| c.include RSpecMixin }
