
# Users Locale Install

    module.exports = header: 'Users Locale Install', handler: ->
      {users, locale} = @config

## LC_* Properties

Modify the /etc/profile file in order to ensure that locale values are all set.
Some Programs might not start if all locale variables are exported with en empty value
such as LC_ALL= . We set all variable to `en_US.UTF-8` by default.

      props = {}
      @execute
        cmd: "locale | grep \'LANG=#{locale.lang}\'"
        code_skipped: 1
      , (err, exists, stdout) ->
        throw err if err
        props['LANG'] = "#{locale.lang}" unless exists
      @execute
        cmd: 'locale | grep \'LC_*\''
      , (err, executed, stdout, stderr) ->
        throw err if err
        for line in string.lines(stdout.trim())
          [_, key, value] = /(LC_.*)=(.*)/.exec line
          continue unless /^\s*$/.test value
          props[key] = if key is 'LC_ALL' then 'C' else "#{locale.lang}"
      @call ->
        @write (
          destination: "#{user.home or '/home/'+user.name}/.ssh/environment"
          write: for k, v of props
            match: RegExp "^#{k}.*$", 'mg'
            replace: "#{k}#{v}" # not setting the = because it is already match in the previous regexp
            append: true
          backup: true
          eof: true
          uid: user.name
          gid: null
          mode: 0o600
        ) for _, user of users

# Dependencies

    string = require 'mecano/lib/misc/string'
