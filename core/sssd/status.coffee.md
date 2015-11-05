
# SSSD Status

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    # exports.push require('./index').configure

    exports.push header: 'SSSD # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: "service sssd status"
        code_skipped: 3
