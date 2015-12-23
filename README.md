# rsync_config Module

## Overview

The **rsync_config** module installs and configures an rsync server including modules.

## Configuration

####`use_xinetd`

Flag to determine if the rsync server should be controlled by xinetd.  **Default: false for Ubuntu and true for RedHAt ** (this option can be overwritten by a host level entry)

#####`address`

The bind address of the daemon, this value is written into /etc/rsyncd.conf, it can be overwritten by setting "--address=x.x.x.x" as an argument to the process itself (can be set on Debian/Ubuntu systems via ***rsync_opts***.  **Default: 0.0.0.0**

#####`merge_modules`

Flag to determine if global and host level modules should be merged together.  If set to false host level modules are used and globals ignored, if however there are no hosts level modules then the globals are used. **Default: true** (this option can be overwritten by a host level entry)

#####`modules`

A hash of rsync modules. **Default: empty hash** (this option can be overwritte/added to by a host level entry)

#####`rsync_fragments`

The location of the folder used to contain module fragments. **Default: /etc/rsync.d**

#####`conf_file`

The location of the rsync daemon configuration file. **Default: /etc/rsyncd.conf**

#####`rsync_opts`

The value to place in the /etc/default/rsync file on Debian/Ubuntu systems for the RSYNC_OPTS option.  **Default: undef** (this option can be overwritten by a host level entry)

#####`flush_config`

Flag to determine if the existing module fragments and rsync configuration file should be deleted, this ensures that only the configuration witin the hiera configuration is present on the system.  **Default: true** (this option can be overwritten by a host level entry)

##Hiera Examples:

* Global Settings

        rsync_config::use_xinetd: false
        rsync_config::rsync_opts: '--address=127.0.0.1'
        rsync_config::address: '127.0.0.1'
        rsync_config::modules:
            'opt':
                path: '/opt'
                comment: 'Opt DR sync'
                read_only: 'no'
                list: 'yes'
                uid: 'root'
                gid: 'root'

* Global and Host Settings

        rsync_config::use_xinetd: false
        rsync_config::rsync_opts: '--address=127.0.0.1'
        rsync_config::address: '127.0.0.1'
        rsync_config::modules:
            'directory1':
                path: '/dir1'
            comment: 'DIR 1'
            read_only: 'no'
            list: 'yes'
            uid: 'root'
            gid: 'root'
        hosts:
            'server1':
                rsync_config::modules:
                    'directory2':
                        path: '/dir2'
                        comment: 'DIR 2'
                        read_only: 'no'
                        list: 'yes'
                        uid: 'root'
                        gid: 'root'
            'server2':
                rsync_config::modules:
                    'directory2':
                        path: '/different-dir2'
                        comment: 'DIR 2'
                        read_only: 'no'
                        list: 'yes'
                        uid: 'root'
                        gid: 'root'
            'server3':
                #HOST LEVEL SETTINGS TAKE PRIORITY OVER GLOBALS
                rsync_config::use_xinetd: true
                rsync_config::rsync_opts: '--address=192.168.12.1 --port 8873'
                rsync_config::address: '192.168.12.1'
                rsync_config::flush_config: false
                rsync_config::modules:
                    'directory2':
                        path: '/anoher-dir2'
                        comment: 'DIR 2'
                        read_only: 'no'
                        list: 'yes'
                        uid: 'root'
                        gid: 'root'

## Dependencies

This module depends on the puppetlabs rsync module
