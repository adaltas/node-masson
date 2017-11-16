
## Check

    module.exports = header: '', handler: (options) ->

## Client Server

      regex = /^server (.*?) /mg
      @system.execute (
        header: 'Client'
        if: match
        cmd: """
        chronyc tracking | grep -P 'Reference ID\\s+:\\s+#{match[1]}'
        """
        retry: 3
        sleep: 3000
      ) while (match = regex.exec options.config) isnt null
