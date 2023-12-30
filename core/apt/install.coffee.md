
# APT Install

    export default header: 'APT Install', handler: ({options}) ->

## Locked

Make sure Yum isnt already running.

      @call header: 'Locked', shy: true, handler: (_, callback) ->
        ssh = @ssh options.ssh
        pidfile_running ssh, '/var/lib/dpkg/lock-frontend', (err, running) ->
          err = Error 'APT is already running' if running
          callback err

## Package updates

      @system.execute
        header: 'Update'
        if: options.update
        cmd: "apt update"
        shy: true

## Package update

      @system.execute
        header: 'Upgrade'
        if: options.upgrade
        cmd: "apt -y upgrade"
        if_exec: '[[ `apt list --upgradable 2>/dev/null | grep -v Listing | wc -l` > 0 ]]'

## User Packages

      @service (
        header: "Install #{name}"
        name: name
        if: active
      ) for name, active of options.packages

## Dependencies

    pidfile_running = require '@nikitajs/core/lib/misc/pidfile_running'
