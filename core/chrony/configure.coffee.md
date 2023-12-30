
# chrony Configure

    export default (service) ->
      {options} = service

## Environment

      options.conf_file ?= '/etc/chrony.conf'

## Configuration

      if options.server is service.node.fqdn
        options.config ?= options.server_config
      else
        options.config ?= options.client_config
