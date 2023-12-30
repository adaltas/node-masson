
# Cgroups Start

Start the cgconfig service.

    export default header: 'Cgroups Start', handler: ->
      @service.start
        name: 'cgconfig'
