
# Masson

Masson is a configuration management, orchestration and do-anything-you-want
tool. It is here to simplify your life installing complex setup and maintaining
dozens, hundreds, or even thousands of servers.

At [Adaltas], we use it to deploy full featured Hadoop Clusters.

## Installation

Run `npm install` to download the project dependencies.

## Usage

The script `./bin/masson` is used to pilot the various command. Run it without 
any arguments to print the help page or as `./bin/big help {command}` to obtain 
help for a particular command.

## Features

*   SSH: ability to execute remote commands using ssh without having the need
    for any client to run on the servers.
*   Documentation: CoffeeScript Literate provides easy to read and self
    documented code.
*   Code as the single source of truth
*   Work entirely offline
*   Easy introspection: source code is easy to navigate and understand

## Developers

```
yarn link nikita
yarn link @nikitajs/core
yarn link @nikitajs/db
yarn link @nikitajs/docker
yarn link @nikitajs/filetypes
yarn link @nikitajs/ipa
yarn link @nikitajs/java
yarn link @nikitajs/krb5
yarn link @nikitajs/ldap
yarn link @nikitajs/lxd
yarn link @nikitajs/service
yarn link @nikitajs/tools
yarn link @rybajs/ambari
yarn link @rybajs/storage
yarn link @rybajs/system
yarn link @rybajs/tools
```



## Documentation

Note, this is a proposal for future Masson evolution and doesnt reflect the
current implementation.

### Option `deps`

* `single`
  Inject a single dependency instead of an array of dependencies.
  Throw an error if more than one service is present
  Equals to null if no service is present
  Used conjointly with `local`, it will return the local service even if the
  service is present on more than one node.
* `local`
  Load the service on the local node if the service is already activated.
* `auto`
  Activate the service.
  Can be used conjointly with `local` to ensure a dependency is executed on 
  every node before a given service.
* `recommanded`
  Mark the depencency as important, only for information purpose.
* `required`
  Ensure a dependency is activated.
  Cannot be used conjointly with `auto`, if a service cannot be automatically
  loaded, then it is pointless to mark it as required.
* `min`
  Ensure a dependency isn't activated on less then a minimum values
* `max`
  Ensure a dependency isn't activated on more then a maximum values

### Usecases:

Considering a service A declared on one node and a service B declared on a 
second node, we defined service B with a dependency of service A with the 
following options:

* Use `local: true` to automatically declare service b on the same node as 
  service A if and only if service B is already defined elsewhere. In the
  service configuration, the dependency will be set as "null" if service B
  was not activated elsewhere.
* Use `local: true, required: true` to automatically declare service B on the
  same node as service A and ensure service A is activated elsewhere.
* Use `local: true, single: true` to automatically declare service B on the
  same node as service A. In the service configuration, the dependency will
  be set as the service object relative to the current node instead of an array
  of services for every nodes.
* Use `auto: true` to automatically activate service B. The service will not
  be declared on any node. In the service configuration, the dependency will
  be set as an empty array if the dependency affinity doesnt match any affinity.
  of services for every nodes.
* Use `auto: true, local: true` to automatically activate service B and declare 
  service B as a dependency of service a.

## Suggestions on api for deps (lucasbak)

### local dependencies

* Use `local: true` for loading the configuration of a module installed `locally` (on the same node).
It enables to reach the configuration in configure directly example, to enrich it or read from it
```cson
  `ryba/hadoop/hdfs_nn/index.coffee.md`
  module.exports:
    deps:
      hadoop_core: module: ryba/hadoop/core, local: true
```
```coffee
  `ryba/hadoop/hdfs_nn/configure.coffee.md`
  module.exports = (service) ->
    service.deps.hadoop_core.options.nameservice
```

### no-instance dependencies

* Use `load: true` for loading the configuration of a module which is not installed nor on the same node
nor on the cluster. It enables the module which does the require to configure automatically configurations
whithout having the module installed.
Note: Should we make a special type for this kind of module, ie this kind of module should
only contain a configure() function (configure.coffee.md).
Using it as a module in configuration declaration (config.coffee) makes no sens
```cson
  `ryba/ranger/admin/index.coffee.md`
  module.exports:
    deps:
      db_admin: module: 'ryba/hadoop/core', load: true
```
```coffee
  `ryba/ranger/admin/configure.coffee.md`
  module.exports = (service) ->
    service.deps.db_admin.options.engine #defined
```

### auto dependencies

Suggest-1:

* Use `auto: true` for installing a module locally (on the same node). as a consequence
`load: true` is implicitly set and the module configuration can be reached.

```cson
  `ryba/oozie/server/index.coffee.md`
  module.exports:
    deps:
      mapred_client: module: 'ryba/hadoop/mapred_client', install: true
```

```coffee
  `ryba/oozie/server/configure.coffee.md`
  module.exports = (service) ->
    service.deps.mapred_client.options #undefined if no other instanced of mapred_client exist on other nodes
```

Suggest-2:

* Use `auto: true`  or an other name `install: true` for installing a module locally (on the same node). `BUT`
to access local configuration for installed dependency `local: true` should be set or all instances will be returned.
like this the same behaviour is applied for local options

```cson
  `ryba/oozie/server/index.coffee.md`
  module.exports:
    deps:
      mapred_client: module: 'ryba/hadoop/mapred_client', install: true, local: true
```

```coffee
  `ryba/oozie/server/configure.coffee.md`
  module.exports = (service) ->
    service.deps.mapred_client.options['mapreduce.java.mapred.opts'] #defined
```

### single dependencies

* User `single: true` for loading the configuration of only one instance of the module.

```cson
  `ryba-env-metal/conf/config.coffee`
  module.exports:
    cluster: 'mycluster': services:
      hdfs_namenode: 
        module: 'ryba/hadoop/hdfs_nn'
        affinity: type: 'nodes', match: 'any', values: ['master01.metal.ryba', 'master02.metal.ryba']
```

```cson
  `ryba/hadoop/hdfs_client/index.coffee.md`
  module.exports:
    deps:
      hdfs_namenode: module: 'ryba/hadoop/hdfs_nn', single: true
```

```coffee
  `ryba/hadoop/hdfs_client/configure.coffee.md`
  module.exports = (service) ->
    service.deps.hdfs_nn.options.nameservice #defined
```

### what about required

* `required: true` is a good option as it explicty declares the necessary deps.
definition of required:true is: a service A required a service B. But it can be on a different node.
On both cases an error is raised at configuration time if the layout of services is not good.
We can have `required: true` or `required:true` and `local: true`
Like this we specifiy if the service should be installed on the same node or not, and load the local config if it is.
Note: `required:true` and `local: true` is DIFFERENT from `auto/install: true` as in the first case the service
must be declared in the configuration and in the second case the local config is not loaded by default.

### options co-habitation

Options `auto: true` does not imply `local: true`. To get configuration for auto dependency, local must be set to true.
An error must be raised if `local: true` and `single: strue` are set.
`load:true` and `local:true` should be incompatible
`load:true` and `auto:true` should be incompatible


## Contributors
 
*   David Worms: <https://github.com/wdavidw>

[Adaltas]: http://www.adaltas.com
