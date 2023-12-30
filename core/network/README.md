
# Network

## Configuration

### Options

The module accept the following properties:

*   `hostname` (boolean, optional)   
    The server hostname as return by the command "hostname" and defined by the 
    property "HOSTNAME" inside the "/etc/sysconfig/network" file, must not be 
    configure globally, default to the "host" property.
*   `hostname_disabled` (boolean, optional)   
    Do not update the hostname, disable the effect of the
    "hostname" property (which itself default to "host"), 
    default to "false".
*   `host_auto` (boolean, optional)   
    Enrich the "/etc/hosts" file with the server ip and hostname present on 
    the cluster, enriching the `host_replace`, default to "false".
*   `hosts_auto` (boolean, optional)   
    Enrich the "/etc/hosts" file with all the hostnames present in 
    the cluster, default to "false".
*   `hosts` (object, optional)   
    Enrich the "/etc/hosts" file with custom adresses, the keys represent the 
    IPs and the value the hostnames.
*   `resolv` (string, optional)   
    Content of the '/etc/resolv.conf' file.
    'systemd-resolved' will be deactivated if set
*   `systemd_resolv` (string, optional)
    Content of '/etc/systemd/resolved.conf'.
    'systemd-resolved' will be activated  if this is set.
    Both `resolv` and `systemd_resolv` can't be set at the same time.
*   `host_replace` (string, optional)   
    Custom hostname to replace in /etc/hosts.
*   `ifcg` (object, optional)   
    Network interfaces configuration, keys are the interface name and filename 
    inside "/etc/sysconfig/network-scripts", value the configuration content.

### Default configuration

```json
{
  "hostname_disabled": false,
  "hosts_auto": false,
}
```

### Example

```json
{
    "hosts_auto": true,
    "hosts": {
      "10.10.10.15": "myserver.hadoop"
    },
    "resolv": "search hadoop\nnameserver 10.10.10.16\nnameserver 10.0.2.3"
    "ifcfg": {
      "eth0": {
        "PEERDNS": "no"
      }
    },
    "host_replace": {
      "10.10.10.11": "master1.new.ryba",
      "10.10.10.12": "master2.new.ryba",
      "10.10.10.13": "master3.new.ryba"
    }
}
```


## Network Check

Forward and reverse DNS mandatory to many service. For exemple both Kerberos 
and Hadoop require a working DNS environment to work properly. A common 
solution to solve an incorrect DNS environment is to install your own DNS 
server. Investigate the "masson/core/bind_server" module for additional 
information.

TODO: in case we are running a local bind server inside the cluster and if this 
server isnt the one currently being installed, we could wait for the server to 
be started before checking the forward and reverse dns of the server.

Dig isn't available by default on CentOS and is installed by the 
"masson/core/bind_client" dependency.

## Check DNS Forward Lookup

Check forward DNS lookup using the configured DNS configuration present inside
"/etc/resolv.conf". Internally, the exectuted command uses "dig".

Note, I didnt find how to restrict dig to return only A records like it
does for CNAME records if you append "cname" at the end of the command.
I assume the A record to always be printed on the last line.

## DNS Reverse Lookup

Check reverse DNS lookup using the configured DNS configuration present inside
"/etc/resolv.conf". Internally, the exectuted command uses "dig".

## Check System Forward Lookup

Check forward DNS lookup using the system configuration which take into account
the local configuration present inside "/etc/hosts". Internally, the exectuted
command uses "getent".

## Check System Reverse Lookup

Check forward DNS lookup using the system configuration which take into account
the local configuration present inside "/etc/hosts". Internally, the exectuted
command uses "getent".

## Check Hostname

Read the server hostname and check it matches the expected FQDN. Internally, 
the executed command is `hostname --fqdn`.
