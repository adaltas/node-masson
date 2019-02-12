
# RNGD Install

    module.exports = header: 'RNGD Install', handler: ({options}) ->

## Entropy

Configure rngd service to use /dev/random device to generate randome number instead of /dev/urandom
Inspred from [rhel7-random-number-generator](https://www.certdepot.net/rhel7-get-started-random-number-generator/)

      @call
        header: 'Service'
      , ->
        @service 'rng-tools'
        @service.init
          target: '/etc/systemd/system/rngd.service'
          source: "#{__dirname}/resources/rng.service.j2"
          local: true
        @service.restart
          name: 'rngd'

[nikita_group]: https://github.com/wdavidw/node-nikita/blob/master/src/group.coffee.md
[nikita_user]: https://github.com/wdavidw/node-nikita/blob/master/src/user.coffee.md
