
# SASLAuthd Check

    module.exports = header: 'SASLAuthd Check', handler: (options) ->
      {saslauthd} = @config
      @execute
        header: "Cmd testsaslauthd"
        if: saslauthd.check.username
        cmd: "testsaslauthd –u #{saslauthd.check.username} –p #{saslauthd.check.password}"
