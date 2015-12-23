class rsync_config (
        $use_xinetd      =    undef,
        $address         =    '0.0.0.0',
        $merge_modules   =    true,
        $modules         =    {},
        $rsync_fragments =    '/etc/rsync.d',
        $conf_file       =    '/etc/rsyncd.conf',
        $rsync_opts      =    undef,
        $flush_config    =    true,
        $se_context      =    'public_content_rw_t',
    )  {

    #most config can be set at either global or host level, therefore check to see if the hosts hash exists
    if ($::host != undef) {
        #if so validate the hash
        validate_hash($::host)

        #if a host level "merge_modules" flag has been set use it, otherwise use the global flag
        $real_merge_modules = $host['rsync_config::merge_modules']? {
            default => $host['rsync_config::merge_modules'],
            undef => $merge_modules,
        }

        #if a host level "flush_config" flag has been set use it, otherwise use the global flag
        $real_flush_config = $host['rsync_config::flush_config']? {
            default => $host['rsync_config::flush_config'],
            undef => $flush_config,
        }

        #if a host level "rsync_opts" value has been set use it, otherwise use the global value
        $real_rsync_opts = $host['rsync_config::rsync_opts']? {
            default => $host['rsync_config::rsync_opts'],
            undef => $rsync_opts,
        }

        $real_use_xinetd = $host['rsync_config::use_xinetd']? {
            default => $host['rsync_config::use_xinetd'],
            undef => $use_xinetd,
        }

        $real_se_context = $host['rsync_config::se_context']? {
            default => $host['rsync_config::se_context'],
            undef => $se_context,
        }

        #if there are host level rsync modules
        if ($host['rsync_config::modules'] != undef) {
            #and we have merging enabled merge global and host
            if ( str2bool($real_merge_modules) ) {
                $real_modules=merge($modules,$host['rsync_config::modules'])
            }
            #if however we have merging disabled, just use host values
            else {
                $real_modules=$host['rsync_config::modules']
            }
        }
        #if there are no host level rsync modules just use globals
        else {
            $real_modules=$modules
        }
    }
    #if the host hash does not exist use global options
    else {
        $real_modules=$modules
        $real_flush_config=$flush_config
        $real_rsync_opts=$rsync_opts
        $real_use_xinetd=$use_xinetd
        $real_se_context=$se_context
    }


    #in order to ensure ONLY the elements specified in hiera are present remove existing config file and fragments if flush_config is true
    if ( str2bool($real_flush_config) ) {
        #first remove any fragments
        exec { 'del rsync fragments':
            command => "rm -f ${rsync_fragments}/*",
            path    => '/usr/bin:/usr/sbin:/bin',
            onlyif  => "test -d ${rsync_fragments}"
        }

        #then remove the config file
        exec { 'del rsync config':
            command => "rm -f ${conf_file}",
            path    => '/usr/bin:/usr/sbin:/bin',
            onlyif  => "test -f ${conf_file}"
        }
    }

    #create rsync module fragments
    create_resources(rsync::server::module, $real_modules)

    if ( $real_use_xinetd == undef ) {
        if ( $::osfamily == 'RedHat' ) {
            $use_use_xinetd = true
        } else {
            $use_use_xinetd = false
        }
    } else {
        $use_use_xinetd = $real_use_xinetd
    }

    if ! defined(Class['rsync::server']) {
        #setup rsync server
        class { 'rsync::server' :
            use_xinetd => $use_use_xinetd,
            address    => $address,
        }
    }

    #if this is a debian type os and rsync_opts is set add the value into /etc/default/rsync
    if ( $::osfamily == 'Debian' ) and ( $real_rsync_opts != undef ) {
        file_line { 'RSYNC_OPTS':
            path  => '/etc/default/rsync',
            line  => "RSYNC_OPTS='${real_rsync_opts}'",
            match => '^RSYNC_OPTS=*',
        }
    }
    if str2bool($::selinux) {
        selboolean { 'rsync_config_rsync_client':
            name       => 'rsync_client',
            persistent => true,
            value      => 'on',
        }
        selboolean { 'rsync_config_rsync_export_all_ro':
            name       => 'rsync_export_all_ro',
            persistent => true,
            value      => 'on',
        }
        selboolean { 'rsync_config_allow_rsync_anon_write':
            name       => 'allow_rsync_anon_write',
            persistent => true,
            value      => 'on',
        }
        # create an array containing all the path's from all the modules and use the se_context define to correctly set the SElinux context
        $folder_list = split(inline_template('<%= @real_modules.values.map{ |x| x["path"]}.join(",") %>'), ',')
        rsync_config::selinux_context  { $folder_list :
            context => $se_context,
        }
    }
}
