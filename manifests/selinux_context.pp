# define to allow the setting of SELinux contexts on each managed folder

define rsync_config::selinux_context (
        $context = 'public_content_rw_t'
    )  {

    exec { "${name}--rsync_selinux_label":
        command => "semanage fcontext -a -t ${context} \"${name}\" && semanage fcontext -a -t ${context} \"${name}(/.*)?\" && restorecon -R -v ${name}"
    }
}
