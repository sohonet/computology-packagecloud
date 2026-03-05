require 'spec_helper'

describe 'packagecloud::repo' do
  let :pre_condition do
    "Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }"
  end

  centos_os = {
    :os => {
      :name => 'CentOS',
      :distro => {
        :id => 'CentOS',
        :release => {
          :full => '8',
          :major => '8',
        }
      },
      :family => 'RedHat',
      :release => {
        :full => '8',
        :major => '8',
      },
      :selinux => {
        :enabled => false,
      },
      :hardware => "x86_64",
      :architecture => "amd64"
    }
  }

  ubuntu_os = {
    :os => {
      :name => 'Ubuntu',
      :distro => {
        :id => 'Ubuntu',
        :codename => 'jammy',
        :release => {
          :full => '22.04',
          :major => '22.04',
        }
      },
      :family => 'Debian',
      :release => {
        :full => '22.04',
        :major => '22.04',
      },
      :selinux => {
        :enabled => false,
      },
      :hardware => "x86_64",
      :architecture => "amd64"
    }
  }

    before(:each) do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(%r{/etc/apt/keyrings/}).and_return(false)

      mock_gpg_response = Net::HTTPOK.new('1.1', '200', 'OK')
      allow(mock_gpg_response).to receive(:body).and_return("-----BEGIN PGP PUBLIC KEY BLOCK-----\nfake-gpg-key\n-----END PGP PUBLIC KEY BLOCK-----\n")

      mock_http = instance_double(Net::HTTP)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:request).and_return(mock_gpg_response)

      allow(Net::HTTP).to receive(:new).and_return(mock_http)
    end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  #
  shared_examples 'creates yumrepo with execs' do
    it do
      is_expected.to compile.with_all_deps
    end
    it do
      is_expected.to contain_class('packagecloud')
    end
    it do
      is_expected.to create_packagecloud__repo('username/publicrepo')
    end
    it do
      is_expected.to contain_file('username_publicrepo').
      with({"path"=>"/etc/yum.repos.d/username_publicrepo.repo",
       "mode"=>"0644",})
    end
    it do
      is_expected.to contain_file('username_publicrepo').with_content(/baseurl=https:\/\/packagecloud.io\/username\/publicrepo\/el\/8\/amd64\//)
    end
    it do
      is_expected.to contain_exec('yum_make_cache_username/publicrepo').
      with(
      {
        "command" => "yum -q makecache -y --disablerepo='*' --enablerepo='username_publicrepo'",
        "path"    => "/usr/bin",
        "require" => "File[username_publicrepo]",
      }
      )
    end
    it do
      is_expected.to create_packagecloud__repo('username/publicrepo')
    end
  end

  shared_examples 'creates apt repo with execs' do
    it do
      is_expected.to compile.with_all_deps
    end
    it do
      is_expected.to contain_class('packagecloud')
    end
    it do
      is_expected.to contain_file('username_publicrepo').
      with({"path"=>"/etc/apt/sources.list.d/username_publicrepo.list",
       "mode"=>"0644",})
    end
    it do
      is_expected.to contain_file('username_publicrepo').with_content(Regexp.new('deb \[signed-by=/etc/apt/keyrings/packagecloud-username_publicrepo.asc\] https://packagecloud.io/username/publicrepo/ubuntu jammy main'))
      is_expected.to contain_file('username_publicrepo').with_content(Regexp.new('deb-src \[signed-by=/etc/apt/keyrings/packagecloud-username_publicrepo.asc\] https://packagecloud.io/username/publicrepo/ubuntu jammy main'))
    end
    it do
      is_expected.to contain_exec('apt_get_update_username_publicrepo').
        with(
          {
            "command" => 'apt-get update -o Dir::Etc::sourcelist="sources.list.d/username_publicrepo.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"',
            "path"    => "/usr/bin/:/bin/",
            "require" => "File[gpg_key_username_publicrepo]",
          }
      )
    end
    it do
      is_expected.to contain_file('gpg_key_username_publicrepo').
        with(
          {
            "path"    => "/etc/apt/keyrings/packagecloud-username_publicrepo.asc",
            "owner"   => "root",
            "group"   => "root",
            "mode"    => "0644",
            "require" => "File[username_publicrepo]",
          }
      )
    end
    it do
      is_expected.to contain_package('apt-transport-https').with_ensure('present')
    end
  end

  context 'rpm repo' do
    context 'with sensible parameters' do
      let(:facts) { centos_os }

      let(:title) { 'username/publicrepo' }

      let(:params) do
        {
          :type          => 'rpm',
        }
      end

      it_behaves_like 'creates yumrepo with execs'

      it do
        is_expected.to contain_exec('yum_make_cache_username/publicrepo').
               with_subscribe(nil)
      end
      it do
        is_expected.to contain_exec('yum_make_cache_username/publicrepo').
               with_refreshonly(nil)
      end
      it do
        is_expected.to create_packagecloud__repo('username/publicrepo')
      end
    end

    context 'with always_update_cache false' do
      let(:facts) { centos_os }


      let(:title) { 'username/publicrepo' }

      let(:params) do
        {
          :type                => 'rpm',
          :always_update_cache => false,
        }
      end
      it_behaves_like 'creates yumrepo with execs'
      it do
        is_expected.to contain_exec('yum_make_cache_username/publicrepo').
               with_subscribe("File[username_publicrepo]")
      end
      it do
        is_expected.to contain_exec('yum_make_cache_username/publicrepo').
               with_refreshonly(true)
      end
    end
  end

  context 'apt repo' do
    context 'with sensible parameters' do
      let(:facts) { ubuntu_os }

      let(:title) { 'username/publicrepo' }

      let(:params) do
        {
          :type          => 'deb',
        }
      end

      it_behaves_like 'creates apt repo with execs'

      it do
        is_expected.to contain_exec('apt_get_update_username_publicrepo').
               with_subscribe(nil)
      end
      it do
        is_expected.to contain_exec('apt_get_update_username_publicrepo').
               with_refreshonly(nil)
      end
    end

    context 'with always_update_cache false' do
      let(:facts) { ubuntu_os }

      let(:title) { 'username/publicrepo' }

      let(:params) do
        {
          :type          => 'deb',
          :always_update_cache => false,
        }
      end

      it_behaves_like 'creates apt repo with execs'

      it do
        is_expected.to contain_exec('apt_get_update_username_publicrepo').
               with_subscribe("File[username_publicrepo]")
      end
      it do
        is_expected.to contain_exec('apt_get_update_username_publicrepo').
               with_refreshonly(true)
      end
    end

    context 'with master_token' do
      let(:facts) do
        ubuntu_os.merge(
          :networking => { :fqdn => 'test.example.com' }
        )
      end

      let(:title) { 'username/publicrepo' }

      let(:params) do
        {
          :type => 'deb',
          :always_update_cache => false,
          :master_token => '1234abcde',
          :server_address => 'https://example.org',
        }
      end

      before(:each) do
        mock_response = Net::HTTPOK.new('1.1', '200', 'OK')
        allow(mock_response).to receive(:body).and_return("poppycock\n")

        mock_http = instance_double(Net::HTTP)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        allow(Net::HTTP).to receive(:new).and_return(mock_http)
      end

      it do
        is_expected.to contain_file('auth_username_publicrepo').with_show_diff(false).with_content( <<~EOF
          # This file is managed by puppet
          # module 'packagecloud'

          machine https://example.org
          login poppycock
          EOF
        )
      end
    end
  end

end
