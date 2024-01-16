require 'uri'
require 'net/https'

Puppet::Functions.create_function(:'packagecloud::get_read_token') do
  dispatch :get_read_token do
    param 'String', :server_address
    param 'String', :repo_name
    param 'String', :master_token
    param 'String', :osname
    param 'String', :distname
    param 'String', :hostname
  end

  def get_read_token(server_address, repo_name, master_token, osname, distname, hostname)
    url = URI("#{server_address}/install/repositories/#{repo_name}/tokens.txt")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request.basic_auth(master_token, '')
    form_data = [['os', osname],['dist', distname],['name', hostname]]
    request.set_form(form_data, 'multipart/form-data')
    https.request(request).body.chomp
  end
end
