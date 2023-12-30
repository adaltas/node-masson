
# Cgroups Configure

The module accept the following properties:

## Source code

    export default (service) ->
      options = service.options

      options.groups ?= {}
