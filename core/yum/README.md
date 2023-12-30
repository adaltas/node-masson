
# YUM

Configure YUM for internet and intranet mode. The Epel repository is optionnaly
deployed.

Note, ntp is installed to encure correct date on the server or HTTPS will fail.

## Configuration

*   `clean`   
*   `copy`   
    Deploy the YUM repository definitions files.   
*   `merge`   
*   `proxy`   
    Inject proxy configuration as declared in the proxy 
    action, default is true   
*   `update`   
    Update packages on the system   
*   `packages` (object[string:boolean])   
    List of packages to be installed by YUM. Set the name of the package as a
    key and mark it activate with the value. Default installed packages are
    "yum-plugin-priorities", "man" and "ksh".   

## Example - activate proxy and install the "git" package

```json
{
  "config": {
    "proxy": "http://my.proxy:8080"
  },
  "packages": {
    "git": true
  }
}
```

## Exemple - custom epel URL

```json
{
  "epel": {
    "enabled": true,
    "url": "http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm"
  }
}
```

## Default Configurations

```json
{
  "merge": true,
  "config": {
    "main": {
      "keepcache": "0"
    }
  },
  "proxy": false,
  "source": null,
  "update": true,
  "clean": "CentOS*",
  "epel": {
    "enabled": false,
    "url": "null",
    "source": null
  },
  "packages": {
    "yum-plugin-priorities": true,
    "man": true,
    "ksh": true
  }
}
```
