
# chrony

chrony is a versatile implementation of the Network Time Protocol (NTP). It can
synchronize the system clock with NTP servers, reference clocks (e.g. GPS 
receiver), and manual input using wristwatch and keyboard. It can also operate
as an NTPv4 (RFC 5905) server and peer to provide a time service to other
computers in the network.

Two programs are included in chrony, chronyd is a daemon that can be started at
boot time and chronyc is a command-line interface program which can be used to
monitor chronyd’s performance and to change various operating parameters whilst
it is running.

Advantages of chronyd over ntpd:

* chronyd can perform usefully in an environment where access to the time
  reference is intermittent. ntpd needs regular polling of the reference to work
  well.
* chronyd can usually synchronise the clock faster and with better time 
  accuracy.
* chronyd quickly adapts to sudden changes in the rate of the clock
* ...

More advantages and feature comparaisons on the 
[chronyd manual](https://chrony.tuxfamily.org/manual.html#Availability).

## Definition

    export default
      configure:
        'masson/core/chrony/configure'
      commands:
        'install': [
          'masson/core/chrony/install'
          'masson/core/chrony/check'
        ]
        'check':
          'masson/core/chrony/check'

## test

Run the test with `mocha core/chrony/test/*.coffee`.
