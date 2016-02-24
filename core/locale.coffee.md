
# Bootstrap Info

Gather various information relative to the targeted system.

    exports = module.exports = []
    exports.push 'masson/bootstrap/connection'
    exports.push 'masson/bootstrap/log'
    exports.push 'masson/core/ssh'

## LC_* Properties

Modify the /etc/profile file in order to ensure that locale values are all set.
Some Programs might not start if all locale variables are exported with en empty value
such as LC_ALL= . We set all variable to `en_US.UTF-8` by default.

    exports.push header: 'Users Locale # Properties', required: true, handler: ->
      {lang,lc} = @config.locale ?= {}
      lang ?= 'en_US.UTF-8'
      props = {}
      @call (_, callback) ->
        @execute
          cmd: "locale | grep \'LANG=#{lang}\'"
          code_skipped: 1
        , (err, executed, stdout) ->
          return callback err if err
          props['LANG'] = "#{lang}" unless executed
          callback err, executed
      @call ->
        @execute
          cmd: 'locale | grep \'LC_*\''
        , (err, executed, stdout, stderr) ->
          throw err if err
          lines = string.lines(stdout)
          for line in lines
            [match] = /(?=[LC_]).*=/.exec line
            value = line.slice(match.length)
            if value.trim().length is 0
              props[match] = if match.indexOf('LC_ALL') isnt 0  then "#{lang}" else 'C'
      @call ->
        users = for _, user of @config.users then user
        for _, user of users
          @write
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


# Dependencies

    string = require('mecano/lib/misc/string')
