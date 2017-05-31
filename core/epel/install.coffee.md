
# Epel Release install

Install the Epel repository. The system should be able to retrieve the epel package.
Generally on yum ennalbed system.
Its deployed by installing the "epel-release" package. It may also be installed from
an url by defining the "yum.epel_url" property. To disable Epel, simply set the `@config.epel`
variable to null

    module.exports = header: 'Epel Install', handler: (options) ->
      epel_rpm_tmp = '/tmp/epel-release.rpm'
    
      @call
        if: options.url?
        timeout: 100000
      , ->
        @file.download
          source: options.url
          target: epel_rpm_tmp
        @system.execute
          cmd: "rpm -Uvh #{epel_rpm_tmp}" 
          unless_exec: 'rpm -qa | grep epel-release'
        @system.remove
          target: epel_rpm_tmp
          shy: true
      
      @tools.repo
        if: options.repo?
        source: options.repo
        target: '/etc/yum.repos.d/epel.repo'
        clean: 'epel*'

      @service
        name: 'epel-release'
