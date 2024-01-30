source 'http://rubygems.org'

group :test do
  if puppetversion = ENV['PUPPET_GEM_VERSION']
    gem 'puppet', puppetversion, :require => false
  else
    gem 'puppet', ENV['PUPPET_VERSION'] || '~> 7'
  end

  gem 'rake'
  gem 'puppet-lint'
  gem 'rspec-puppet', :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem 'puppet-syntax'
  gem 'puppetlabs_spec_helper'
  gem 'simplecov'
  gem 'metadata-json-lint'
end

group :development do
  gem 'puppet-blacksmith'
  gem 'guard-rake'
end

group :system_tests do
  gem 'librarian-puppet'
  gem 'test-kitchen'
  gem 'serverspec'
  gem 'psych'
  gem 'kitchen-vagrant'
  gem 'kitchen-puppet'
  gem 'vagrant-wrapper'
end
