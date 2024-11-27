
# Configuration discovery

Masson configuration is discovered from files and directories. It supports multiple file formats.

## Usage

In the command line, the `-c --config` argument list one or multiple search path.

## Configuration structure

Configuration is splitted among the following properties.

- `actions`  
  [Actions](./config-actions.md) scheduled for execution.
- `masson`  
  [Masson]('./config-masson.md) configuration.
- `nodes`  
  Nodes where to target action execution.
- `secrets`  
  Secrets exposed to your actions.

## Discovery strategy

The supported file format are YAML (`.yml`, `.yaml`), JSON (`.json`) and JavaScript (`.js`).

If the path is a directory, all the files present inside are loaded given they match the patterns:

- `**/*.[yaml|yml]`
- `**/*.json`
- `**/*.js`

## Merging strategy

All files discovered from the search directories are merged to build the final configuration. Parent directories and filenames, split by dots (`.`), are leveraged to build the path of an action.

A search directory `./conf` with a configuration file stored in `./conf/actions/my_services.yml` and a child action named `my_component` is merged in the configuration as `actions.my_services.actions.my_components`

Simlarly, a search directory `./conf` with a configuration file stored in `./conf/actions.my_services.yml` and a child action named `my_component` is merged in the configuration as `actions.my_services.actions.my_components`.
