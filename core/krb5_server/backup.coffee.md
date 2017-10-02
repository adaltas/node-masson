
# Kerberos Server Backup

    module.exports = name: "Kerberos Server Backup", handler: (options) ->
      @tools.backup
        header: 'Database'
        name: 'kerberos'
        cmd: 'kdb5_util dump'
