
# SASLAuthd Install

    module.exports = header: 'SASLAuthd Install', handler: (options) ->
      {saslauthd} = @config

## Packages

      @call header: 'Packages', ->
        @service
          name: 'cyrus-sasl'
        @service
          name: 'cyrus-sasl-ldap'
      
      @file.properties
        header: 'Sysconf'
        target: '/etc/sysconfig/saslauthd'
        content: saslauthd.sysconfig
        mode: 0o0644
      
      @file.properties
        header: 'Conf'
        target: saslauthd.conf_file
        content: saslauthd.conf
        mode: 0o0644
      
      @service
        header: 'Start'
        if: -> @status()
        srv_name: 'saslauthd'
        startup: true
        action: ['start', 'restart']
