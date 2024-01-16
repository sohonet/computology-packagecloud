RSpec.configure do |c|
  c.mock_with :rspec
end

require 'hiera'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
