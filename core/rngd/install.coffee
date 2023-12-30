
export default
  header: 'RNGD Install'
  handler: ({options}) ->
    # Entropy
    # Configure rngd service to use /dev/random device to generate randome number instead of /dev/urandom
    # Inspred from [rhel7-random-number-generator](https://www.certdepot.net/rhel7-get-started-random-number-generator/)
    @call
      header: 'Service'
    , ->
      @service 'rng-tools'
      @service.init
        target: '/usr/lib/systemd/system/rngd.service'
        source: "#{__dirname}/resources/rngd.service.j2"
        local: true
      @service.restart
        name: 'rngd'
