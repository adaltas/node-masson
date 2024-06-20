
# Configuration discovery

Masson configuration is discovered from files and directories. In the command line, the `-c --config` argument list one or multiple search path. If the path match a directory, all the files inside are loaded.

The supported file format are YAML, JSON and JavaScript.

All files discovered from the search directories are merged to build the final configuration. Parent directories and filenames, split by dots (`.`), are leveraged to build the path of an action.

A search directory `./conf` with a configuration file stored in `./conf/actions/my_services.yml` and a child action named `my_component` is merged in the configuration as `actions.my_services.actions.my_components`

Simlarly, a search directory `./conf` with a configuration file stored in `./conf/actions.my_services.yml` and a child action named `my_component` is merged in the configuration as `actions.my_services.actions.my_components`.
