
# Cgroups Install

    module.exports = header: 'Cgroups Install', handler: (options) ->
      {cgroups} = @config

## Packages
Install 'libcroup' packages. On Centos/Redhat 7 libcgroup-tools is needed to provide
centos/Redhat 6 like behavior.
Centos/Redhat 7 moves the resource management settings from the process level to
the application level by binding the system of cgroup hierarchies with the systemd unit tree.

      @service name: 'libcgroup'
      @service
        if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and options.store['mecano:system:release'][0] is '7'
        header: 'libcroup services'
        name: 'libcgroup-tools'
      @service.startup
        name: 'cgconfig'
        startup: true
        action: 'start'

## Dependencies

    string = require 'mecano/lib/misc/string'
    path = require 'path'
