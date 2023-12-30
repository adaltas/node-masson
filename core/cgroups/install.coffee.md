
# Cgroups Install

    export default header: 'Cgroups Install', handler: ->

## Packages

Install 'libcroup' packages. On Centos/Redhat 7 libcgroup-tools is needed to provide
centos/Redhat 6 like behavior.

Centos/Redhat 7 moves the resource management settings from the process level to
the application level by binding the system of cgroup hierarchies with the systemd unit tree.

      @service name: 'libcgroup'
      @service
        if_os: name: ['redhat','centos'], version: '7'
        header: 'libcroup services'
        name: 'libcgroup-tools'
      @service.startup
        name: 'cgconfig'
        startup: true
        state: 'started'
