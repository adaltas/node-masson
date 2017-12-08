
# Masson

Masson is a configuration management, orchestration and do-anything-you-want
tools. It is here to simplify your life installing complex setup and maintaining
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
*   Code as the single source of thruth
*   Work entirely offline
*   Easy introspection: source code is easy to navigate and understand

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

## Contributors
 
*   David Worms: <https://github.com/wdavidw>

[Adaltas]: http://www.adaltas.com
