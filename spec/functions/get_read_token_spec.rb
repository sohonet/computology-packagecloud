require 'spec_helper'
require 'net/http'
require 'puppet/parser/functions/get_read_token'


describe 'get_read_token' do
  before do
    allow(scope).to receive(:lookupvar).with('::operatingsystem') { 'ubuntu' }
    allow(scope).to receive(:lookupvar).with('::operatingsystemrelease') { '20.04' }
    allow(scope).to receive(:lookupvar).with('::fqdn') { 'test-host' }
  end

  context 'no proxy http' do
    it do
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      http = instance_double(Net::HTTP) 
      allow(Net::HTTP).to receive(:new).with('packagecloud.io', 80) { http }
      expect(http).to receive(:start) { response }
      expect(response).to receive(:body) { 'read-token' }

      is_expected.to run.with_params('test-repo', 'master_token', 'http://packagecloud.io', "", nil).and_return('read-token')
    end
  end

  context 'no proxy https' do
    it do
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      http = instance_double(Net::HTTP) 
      allow(Net::HTTP).to receive(:new).with('packagecloud.io', 443) { http }

      ssl_store = instance_double(OpenSSL::X509::Store)
      allow(OpenSSL::X509::Store).to receive(:new) { ssl_store }
      allow(ssl_store).to receive(:set_default_paths)

      expect(http).to receive(:start) { response }
      expect(http).to receive(:use_ssl=).with(true)
      expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      expect(http).to receive(:cert_store=).with(ssl_store)
      expect(response).to receive(:body) { 'read-token' }

      is_expected.to run.with_params('test-repo', 'master_token', 'https://packagecloud.io', nil, nil).and_return('read-token')
    end
  end

  context 'with proxy http' do
    it do
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      http = instance_double(Net::HTTP) 
      allow(Net::HTTP).to receive(:new).with('packagecloud.io', 80, 'localhost', '8080') { http }
      expect(http).to receive(:start) { response }
      expect(response).to receive(:body) { 'read-token' }

      is_expected.to run.with_params('test-repo', 'master_token', 'http://packagecloud.io', 'localhost', '8080').and_return('read-token')
    end
  end

  context 'with proxy https' do
    it do
      response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      http = instance_double(Net::HTTP) 
      allow(Net::HTTP).to receive(:new).with('packagecloud.io', 443, 'localhost', '8080') { http }

      ssl_store = instance_double(OpenSSL::X509::Store)
      allow(OpenSSL::X509::Store).to receive(:new) { ssl_store }
      allow(ssl_store).to receive(:set_default_paths)

      expect(http).to receive(:start) { response }
      expect(http).to receive(:use_ssl=).with(true)
      expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      expect(http).to receive(:cert_store=).with(ssl_store)
      expect(response).to receive(:body) { 'read-token' }

      is_expected.to run.with_params('test-repo', 'master_token', 'https://packagecloud.io', 'localhost', '8080').and_return('read-token')
    end
  end
end
