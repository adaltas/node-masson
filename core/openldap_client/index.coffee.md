
# OpenLDAP Client

    exports = module.exports = []

## Configuration

*   `openldap_client.config` (object)   
    Configuration of the "/etc/openldap/ldap.conf" file.   
*   `openldap_client.config.TLS_CACERTDIR` (string)   
    Default to "/etc/openldap/cacerts".   
*   `openldap_client.config.TLS_REQCERT` (string)   
    Default to "allow".   
*   `openldap_client.config.TIMELIMIT` (string|number)   
    Default to "15".   
*   `openldap_client.config.TIMEOUT` (string|number)  
    Default to "10".    
*   `openldap_client.suffix` (string)   
    LDAP suffix used by the test, default to null or discovered.   
*   `openldap_client.root_dn` (string)   
    LDAP user used by the test, default to null or discovered.   
*   `openldap_client.root_password` (string)   
    LDAP password used by the test, default to null or discovered.   
*   `openldap_client.certificates` (array)   
    Paths to the certificates to upload.   

The properties `openldap_client.config.BASE`, `openldap_client.suffix`, 
`openldap_client.root_dn` and `openldap_client.root_password` are discovered if 
there is only one LDAP server or if an LDAP server is deployed on the same 
server.

The property `openldap_client.config.URI` is generated with the list of 
configured LDAP servers.

Example:

```json
{
  "openldap_client": {
    "config": {
      "TLS_REQCERT": "allow",
      "TIMELIMIT": "15".
      "TIMEOUT": "10"
    },
    "certificates": [
      "./cert.pem"
    ]
  }
}
```

    module.exports.configure = (ctx) ->
      config = ctx.config.openldap_client ?= {}
      ctx.config.openldap_client.config ?= {}
      openldap_servers = ctx.hosts_with_module 'masson/core/openldap_server'
      # openldap_server = ctx.hosts_with_module 'masson/core/openldap_server'
      if openldap_servers.length isnt 1
        openldap_servers = openldap_servers.filter (server) -> server is ctx.config.host
      openldap_server = if openldap_servers.length is 1 then openldap_servers[0] else null
      openldap_servers_secured = ctx.hosts_with_module 'masson/core/openldap_server/install_tls'
      uris = {}
      for server in openldap_servers then uris[server] = "ldap://#{server}"
      for server in openldap_servers_secured then uris[server] = "ldaps://#{server}"
      uris = for _, uri of uris then uri
      if openldap_server
        ctx_server = ctx.hosts[openldap_server]
        require('../openldap_server').configure ctx_server
        config.config['BASE'] ?= ctx_server.config.openldap_server.suffix
        config.suffix ?= ctx_server.config.openldap_server.suffix
        config.root_dn ?= ctx_server.config.openldap_server.root_dn
        config.root_password ?= ctx_server.config.openldap_server.root_password
      config.config['URI'] ?= uris.join ' '
      config.config['TLS_CACERTDIR'] ?= '/etc/openldap/cacerts'
      config.config['TLS_REQCERT'] ?= 'allow'
      config.config['TIMELIMIT'] ?= '15'
      config.config['TIMEOUT'] ?= '20'

    exports.push commands: 'install', modules: [
      'masson/core/openldap_client/install'
      'masson/core/openldap_client/wait'
      'masson/core/openldap_client/check'
    ]

    exports.push commands: 'check', modules: [
      'masson/core/openldap_client/wait'
      'masson/core/openldap_client/check'
    ]


