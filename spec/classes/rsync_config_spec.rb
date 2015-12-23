require 'spec_helper'

describe 'rsync_config', :type => 'class' do

  host_hash   = {'rsync_config::modules'   => { 'opt-slow' => {
        'path'       => '/opt-slow',
        'comment'    => 'Opt Slow DR sync',
        'read_only'  => 'no',
        'list'       => 'yes',
        'uid'        => 'root',
        'gid'        => 'root' }
        }
      }

  host_hash_no_merge = {'rsync_config::modules'   => { 'opt-slow' => {
        'path'       => '/opt-slow',
        'comment'    => 'Opt Slow DR sync',
        'read_only'  => 'no',
        'list'       => 'yes',
        'uid'        => 'root',
        'gid'        => 'root' }
        },
        'rsync_config::merge_modules' => false
      }

  host_no_merge      = { 'rsync_config::merge_modules' => false}

  global_rsync       = { 'opt' => {
        'path'       => '/opt',
        'comment'    => 'Opt DR sync',
        'read_only'  => 'no',
        'list'       => 'yes',
        'uid'        => 'root',
        'gid'        => 'root' }
       }
  
  se_context         =    'public_content_rw_t'

  context "Should configure rsync with xinetd" do

    let(:params) {
     { :use_xinetd    => true }
    }

    #osfamily required by puppetlabs/xinetd module
    let(:facts) {
     { :osfamily     => 'Debian' }
    }

    it do
      should contain_class('rsync')
      should contain_class('rsync::server')
      should contain_class('xinetd')
    end
  end

  context "Should configure rsync without xinetd" do

    let(:params) {
     { :use_xinetd    => false }
    }

    it do
      should contain_class('rsync')
      should contain_class('rsync::server')
      should_not contain_class('xinetd')
    end
  end

  context "Should delete old config before re-creating" do

    let(:params) {
     { :flush_config    => true,
       :use_xinetd    => false
     }
    }

    it do
      should contain_class('rsync')
      should contain_class('rsync::server')
      should contain_exec('del rsync config')
      should contain_exec('del rsync fragments')
    end
  end

  context "Should not delete old config before re-creating" do

    let(:params) {
     { :flush_config    => false,
       :use_xinetd    => false
     }
    }

    it do
      should contain_class('rsync')
      should contain_class('rsync::server')
      should_not contain_exec('del rsync config')
      should_not contain_exec('del rsync fragments')
    end
  end

  context "Should update rsync defauls on Debian type systems" do

    let(:params) {
     { :use_xinetd    => false,
       :rsync_opts    => '--address=192.168.1.1'
     }
    }

    let(:facts) {
     { :osfamily     => 'Debian' }
    }

    it do
      should contain_file_line('RSYNC_OPTS').with(
            'path'            => '/etc/default/rsync',
            'match'           => '^RSYNC_OPTS=*',
            'line'            => "RSYNC_OPTS='--address=192.168.1.1'"
      )
    end
  end

  context "Should configure rsync server from global config" do

    let(:params) {
     { :address       => '192.168.1.1',
       :modules       => global_rsync,
       :use_xinetd    => false
     }
    }

    it do
      should contain_class('rsync')
      should contain_class('rsync::server')
      should contain_rsync__server__module('opt').with(
            'name'            => 'opt',
	          'path'            => '/opt',
            'comment'         => 'Opt DR sync',
            'read_only'       => 'no',
            'list'            => 'yes',
            'uid'             => 'root',
            'gid'             => 'root',
            'write_only'      => 'no',
            'incoming_chmod'  => '0644',
            'outgoing_chmod'  => '0644',
            'max_connections' => '0',
            'lock_file'       => '/var/run/rsyncd.lock'
	    )
      should_not contain_rsync__server__module('opt-slow')
      should contain_file('/etc/rsync.d/header').with_content(/\s*address = 192.168.1.1\s*/)

    end
  end

  context "Should configure rsync server from global and host config" do

    let(:params) {
     { :address       => '192.168.1.1',
       :modules       => global_rsync,
       :use_xinetd    => false
     }
    }

    let(:facts) {
     { :host => host_hash }
    }

    it do
      should contain_class('rsync')
      should contain_class('rsync::server')
      should contain_rsync__server__module('opt').with(
            'name'            => 'opt',
            'path'            => '/opt',
            'comment'         => 'Opt DR sync',
            'read_only'       => 'no',
            'list'            => 'yes',
            'uid'             => 'root',
            'gid'             => 'root',
            'write_only'      => 'no',
            'incoming_chmod'  => '0644',
            'outgoing_chmod'  => '0644',
            'max_connections' => '0',
            'lock_file'       => '/var/run/rsyncd.lock'
      )
      should contain_rsync__server__module('opt-slow').with(
            'name'            => 'opt-slow',
            'path'            => '/opt-slow',
            'comment'         => 'Opt Slow DR sync',
            'read_only'       => 'no',
            'list'            => 'yes',
            'uid'             => 'root',
            'gid'             => 'root',
            'write_only'      => 'no',
            'incoming_chmod'  => '0644',
            'outgoing_chmod'  => '0644',
            'max_connections' => '0',
            'lock_file'       => '/var/run/rsyncd.lock'
      )
      should contain_file('/etc/rsync.d/header').with_content(/\s*address = 192.168.1.1\s*/)

    end
  end


  context "Should configure rsync server from host config only as merging is disabled" do

    let(:params) {
     { :address       => '192.168.1.1',
       :modules       => global_rsync,
       :use_xinetd    => false
     }
    }

    let(:facts) {
     { :host => host_hash_no_merge }
    }

    it do
      should contain_class('rsync')
      should contain_class('rsync::server')
      should_not contain_rsync__server__module('opt')
      should contain_rsync__server__module('opt-slow').with(
            'name'            => 'opt-slow',
            'path'            => '/opt-slow',
            'comment'         => 'Opt Slow DR sync',
            'read_only'       => 'no',
            'list'            => 'yes',
            'uid'             => 'root',
            'gid'             => 'root',
            'write_only'      => 'no',
            'incoming_chmod'  => '0644',
            'outgoing_chmod'  => '0644',
            'max_connections' => '0',
            'lock_file'       => '/var/run/rsyncd.lock'
      )
      should contain_file('/etc/rsync.d/header').with_content(/\s*address = 192.168.1.1\s*/)

    end
  end

  context "Should fall back to global config as there is no host modules defined" do

    let(:params) {
     { :address       => '192.168.1.1',
       :modules       => global_rsync,
       :merge_modules => false,
       :use_xinetd    => false
     }
    }

    let(:facts) {
     { :host => host_no_merge }
    }

    it do
      should contain_class('rsync')
      should contain_class('rsync::server')
      should_not contain_rsync__server__module('opt-slow')
      should contain_rsync__server__module('opt').with(
            'name'            => 'opt',
            'path'            => '/opt',
            'comment'         => 'Opt DR sync',
            'read_only'       => 'no',
            'list'            => 'yes',
            'uid'             => 'root',
            'gid'             => 'root',
            'write_only'      => 'no',
            'incoming_chmod'  => '0644',
            'outgoing_chmod'  => '0644',
            'max_connections' => '0',
            'lock_file'       => '/var/run/rsyncd.lock'
      )
      should contain_file('/etc/rsync.d/header').with_content(/\s*address = 192.168.1.1\s*/)

    end
  end

  context "Should set selinux booleans" do
    let(:params){
      {:modules       => global_rsync,
       :se_context    => se_context
      }
    }
    let(:facts){
      {:selinux => 'true',
       :host => host_hash
      }
    }
    it do
      should contain_selboolean('rsync_config_rsync_client').with(
        'value'      => 'on',
        'persistent' => true
      )
      should contain_selboolean('rsync_config_rsync_export_all_ro').with(
        'value'      => 'on',
        'persistent' => true
      )
      should contain_selboolean('rsync_config_allow_rsync_anon_write').with(
        'value'      => 'on',
        'persistent' => true
      )
      should contain_exec('/opt--rsync_selinux_label').with(
        'command' => 'semanage fcontext -a -t public_content_rw_t "/opt" && semanage fcontext -a -t public_content_rw_t "/opt(/.*)?" && restorecon -R -v /opt'
      )
      should contain_exec('/opt-slow--rsync_selinux_label').with(
        'command' => 'semanage fcontext -a -t public_content_rw_t "/opt-slow" && semanage fcontext -a -t public_content_rw_t "/opt-slow(/.*)?" && restorecon -R -v /opt-slow'
      )
    end
  end

end
