
# Cgroups Start

Start the cgconfig service.

    module.exports = header: 'Cgroups Start', handler: ->
      @service.start
        name: 'cgconfig'
