require 'uri'
require 'net/https'

Puppet::Functions.create_function(:'packagecloud::fetch_gpg_key') do
  dispatch :fetch_gpg_key do
    param 'String', :server_address
    param 'String', :repo_name
    param 'Any', :read_token
    param 'String', :dest_path
  end

  def fetch_gpg_key(server_address, repo_name, read_token, dest_path)
    return File.read(dest_path) if File.exist?(dest_path)

    url = URI("#{server_address}/#{repo_name}/gpgkey")
    max_redirects = 5
    max_redirects.times do
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = (url.scheme == 'https')
      request = Net::HTTP::Get.new(url)
      if read_token
        request.basic_auth(read_token, '')
      end
      response = https.request(request)

      case response
      when Net::HTTPSuccess
        return response.body
      when Net::HTTPRedirection
        url = URI(response['location'])
      else
        Puppet.warning("Packagecloud: Unable to retrieve GPG key for repo #{repo_name}: #{response.code} #{response.message}")
        return ''
      end
    end
    raise "Too many redirects fetching GPG key from #{server_address}/#{repo_name}/gpgkey"
  end
end
