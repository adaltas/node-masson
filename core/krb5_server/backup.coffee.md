
# Kerberos Server Backup

    export default name: "Kerberos Server Backup", handler: ->
      @tools.backup
        header: 'Database'
        name: 'kerberos'
        cmd: 'kdb5_util dump'
