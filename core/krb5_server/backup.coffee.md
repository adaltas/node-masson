
# Kerberos Server Backup

    module.exports = name: "Kerberos Server Backup", timeout: -1, label_true: 'BACKUPED', handler: ->
      @tools.remove
        header: 'Database'
        name: 'kerberos'
        cmd: 'kdb5_util dump'
