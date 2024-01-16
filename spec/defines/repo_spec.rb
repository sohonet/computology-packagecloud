require 'spec_helper'

describe 'packagecloud::repo' do
  let :pre_condition do
    "Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }"
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
      is_expected.to contain_file('username_publicrepo').with_content(/deb https:\/\/packagecloud.io\/username\/publicrepo\/ubuntu  main/)
      is_expected.to contain_file('username_publicrepo').with_content(/deb-src https:\/\/packagecloud.io\/username\/publicrepo\/ubuntu  main/)
    end
    it do
      is_expected.to contain_exec('apt_get_update_username_publicrepo').
        with(
          {
            "command" => 'apt-get update -o Dir::Etc::sourcelist="sources.list.d/username_publicrepo.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"',
            "path"    => "/usr/bin/:/bin/",
            "require" => "Exec[apt_key_add_username_publicrepo]",
          }
      )
    end
    it do
      is_expected.to contain_exec('apt_key_add_username_publicrepo').
        with(
          {
            "command" => 'wget --auth-no-challenge -qO - https://packagecloud.io/username/publicrepo/gpgkey | apt-key add -',
            "path"    => "/usr/bin/:/bin/",
            "require" => "File[username_publicrepo]",
          }
      )
    end
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

  context 'rpm repo' do
    context 'with sensible parameters' do
      let(:facts) { centos_os }

      let(:title) { 'username/publicrepo' }

      let(:params) do
        {
          :type => 'rpm',
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
          :type => 'rpm',
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
          :type => 'deb',
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
          :type => 'deb',
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
  end

end
