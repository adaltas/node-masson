
export default
  header: 'YUM Install'
  handler: ({options}) ->
    # Locked
    # Make sure Yum isnt already running.
    @system.running
      header: 'Lock Check'
      target: '/var/run/yum.pid'
    , (err, {status}) ->
      throw err if err
      throw Error 'Yum is already running' if status
    ## Configuration
    # Read the existing configuration in '/etc/yum.conf', 
    # merge server configuration and write the content back.
    # More information about configuring the proxy settings 
    # is available on [the centos website](http://www.centos.org/docs/5/html/yum/sn-yum-proxy-server.html)
    @file.ini
      header: 'Configuration'
      content: options.config
      target: '/etc/yum.conf'
      merge: true
      backup: true
    ## Yum Repositories
    # Upload the YUM repository file definition present in 
    # "options.repo" to the yum repository directory 
    # in "/etc/yum.repos.d"
    @tools.repo
      if: !!options.repo.source
      header: 'Repo'
      source: options.repo.source
      update: options.repo.update
      target: options.repo.target
      clean: options.repo.clean
    # Custom Repositories
    # Allow administrators to upload additional repos.
    @call
      header: 'Custom Repos',
      if: options.additional_repos
    , ->
      for name, repo of options.additional_repos
        @tools.repo
          if: repo.source?
          source: repo.source
          update: repo.update
          target: repo.target
          name: repo.name
          clean: repo.clean
    # Epel
    # Install the Epel repository. This is by default desactivated and the repository 
    # is deployed by installing the "epel-release" package. It may also be installed 
    # from an url by defining the "yum.epel.url" property. To activate Epel, simply 
    # set the property "yum.epel.enabled" to "true".
    @call
      header: 'Epel'
      if: options.epel?.enabled
    , ->
      epel_rpm_tmp = '/tmp/epel-release.rpm'
      @call
        if: options.epel.url?
        unless_exec: 'rpm -qa | grep epel-release'
        timeout: 100000
      , ->
        @file.download
          source: options.epel.url
          target: epel_rpm_tmp
          shy: true
        @system.execute
          cmd: "rpm -Uvh #{epel_rpm_tmp}"
        @system.remove
          target: epel_rpm_tmp
          shy: true
      @tools.repo
        if: options.epel.source?
        source: options.epel.source
        target: '/etc/yum.repos.d/epel.repo'
        clean: 'epel*'
      @service
        name: 'epel-release'
    # Package Update
    @system.execute
      header: 'Update'
      if: options.update
      cmd: "yum -y update"
      if_exec: '[[ `yum check-update | egrep "(.i386|.x86_64|.noarch|.src)" | wc -l` > 0 ]]'
    # User Packages
    @service (
      header: "Install #{name}"
      name: name
      if: active
    ) for name, active of options.packages
