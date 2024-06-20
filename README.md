
# Cloudera validation script

## Installation

The script require Node.js version 22. Further versions might work as well. Use [n-install](https://github.com/mklement0/n-install) to install and manage specific Node.js versions.

The following files must be created or imported:

- `./conf/nodes.yml` Declare the targeted nodes composing the cluster.
- `./conf/secrets.yml` Configure sensitive informations such as passwords.

## Usage

Run all check.

```bash
./bin/masson lib/index.js
```

Run check with module and node filtering.

```bash
./bin/masson check -n 'master-*' -m './lib/disks-fstab-*' 
```

## Configuration

Search directories are defined with additionnal `-c --config` parameters. Multiple search directories may be provided from the CLI.

Configuration files are defined in YAML. 

All files discovered from the search directories are merged to build the final configuration. Parent directories and filenames, split by dots (`.`), are leveraged to build the path of an action.

A search directory `./conf` with a configuration file stored in `./conf/actions/my_services.yml` and a child action named `my_component` is merged in the configuration as `actions.my_services.actions.my_components`

Simlarly, a search directory `./conf` with a configuration file stored in `./conf/actions.my_services.yml` and a child action named `my_component` is merged in the configuration as `actions.my_services.actions.my_components`.

Configuration is splitted among the following properties.

- `actions`   
  List of actions and group actions with their definition.
- `nodes`   
  Node where to target action execution.
- `secrets`
  List of secrets exposed to your actions.

## Action definitions

Actions are declared inside the `actions` configuration property. 

An action respects the Nikita action format. It uses the long format definition, for example `{ metadata: { header: "My Service" }, config: { key: "value"}}`.

The short form, for example `{ $header: "My Service", key: "value" }`, is used as usual when implementing action handler functions.

## Action groups

Actions may be grouped toguether into parent action under the `actions.<parent>.actions` property. Only leaf actions are executed and their properties are merged with their parent actions.

For example, a group action named `my-database` contains 2 child actions `install` and `check`.

```yml
actions:
  my-database:
    metadata:
      header: My HA Database
    config:
      username: admin
      password: '{{secrets.databases.my.password}}'
    nodes: 'master-*'
    actions:
      install:
        module: my-db/install
        metadata:
          header: Install
        config:
          package: 'my-db'
      check:
        module: my-db/start
        metadata:
          header: Check
```

## Action filtering

When no arguments is provided, all actions are scheduled for execution. It is possible gain control on which actions are executed with the following filters.

- `action`   
  The action name. Use a path notation when the action is a child of others actions, for example `./bin/masson check -a '/my-service/start-*'`.
- `module`   
  The module name used by an action. Mode are ESM module names, for example `@my-company/my-packages/actions/start-*`.
- `node`   
  The node name, domain or FQDN where the action is executed.

Filters may be combined toguether and used multiple times, for example `./bin/masson -a '**/*-start-*' -h 'master-*' -h 'worker-*'`.

## Logs

A log file is generated for each node in the Markdown format. Logs are stored inside the "./logs" folder and log files are named after the node name, such as "<node_name>.md"
