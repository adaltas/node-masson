
## Check

    export default header: 'chrony Check', handler: ({options}) ->

## Client Server

Use `chrony tracking` to print the current reference source. The `-n` disables
resolving of IP addresses.

      regex = /^server (.*?) /mg
      @system.execute (
        header: 'Client'
        if: match
        cmd: """
        old="chronyc tracking | grep -P 'Reference ID\\s+:\\s+#{match[1]}'"
        new="chronyc -n tracking | grep -P 'Reference ID\\s+:\\s+[A-Z0-9]+\\s+\\(#{match[1]}\\)'"
        `echo $old` || `echo $new`
        """
        retry: 3
        sleep: 3000
      ) while (match = regex.exec options.config) isnt null
