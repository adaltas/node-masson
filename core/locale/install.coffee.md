
# Users Locale Install

    export default header: 'Locale Install', handler: ({options}) ->

## LC_* Properties

Modify the /etc/profile file in order to ensure that locale values are all set.
Some Programs might not start if all locale variables are exported with en empty value
such as LC_ALL= . We set all variable to `en_US.UTF-8` by default.

      props = {}
      @system.execute
        cmd: "locale | grep \'LANG=#{options.lang}\'"
        code_skipped: 1
        shy: true
      , (err, exists, stdout) ->
        throw err if err
        props['LANG'] = "#{options.lang}" unless exists
      @system.execute
        cmd: 'locale | grep \'LC_*\''
        shy: true
      , (err, data) ->
        throw err if err
        for line in string.lines(data.stdout.trim())
          [_, key, value] = /(LC_.*)=(.*)/.exec line
          continue unless /^\s*$/.test value
          props[key] = if key is 'LC_ALL' then 'C' else "#{options.lang}"
      @call
        header: 'SSH Env'
        handler: ->
          @file (
            target: "#{user.home or '/home/'+user.name}/.ssh/environment"
            write: for k, v of props
              match: RegExp "^#{k}.*$", 'mg'
              replace: "#{k}=#{v}"
              append: true
            backup: true
            eof: true
            uid: user.name
            gid: null
            mode: 0o600
          ) for _, user of options.users

# Dependencies

    string = require '@nikitajs/core/lib/misc/string'
