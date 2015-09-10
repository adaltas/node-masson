
# Kerberos Server Backup

    module.exports = []
    
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    # module.exports.push require('./').configure

    module.exports.push name: "Kerberos Server # Backup Database", timeout: -1, label_true: 'BACKUPED', handler: ->
      @backup
        name: 'kerberos'
        cmd: 'kdb5_util dump'
