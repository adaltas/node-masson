
# OpenLDAP Client

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

    export default
      deps:
        yum: module: 'masson/core/yum', local: true
        ssl: module: '@rybajs/tools/ssl', local: true
        openldap_server: module: 'masson/core/openldap_server'
      configure:
        'masson/core/openldap_client/configure'
      commands:
        'check':
          'masson/core/openldap_client/check'
        'install': [
          'masson/core/openldap_client/install'
          'masson/core/openldap_client/check'
        ]
