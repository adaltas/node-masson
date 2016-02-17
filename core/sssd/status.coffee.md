
# SSSD Status

    module.exports = header: 'SSSD # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name: 'sssd'
