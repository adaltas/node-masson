
# Masson definition

Masson properties alter the global behavior of Masson.

It consists of the following properties.

- `masson.log`  
  Control the various log behavior.
- `masson.log.cli (boolean)`  
  Enable the CLI log ouput, default is `true`.
- `masson.log.md (boolean)`  
  Enable the Markdown log ouput.
- `masson.nikita`  
  Default properties applied to all actions.
- `patterns` (default `["**/*.yml", "**/*.yaml", "**/*.js", "**/*.json"]`)  
  Accept file pattern when search path is a directory.
- `masson.register`  
  An array of instructions to register Nikita actions. Objects map keys representing the action's namespaces to values representing the action definition. When defined as an object, actions are registered inside Nikita sessions. A string represents the module name which is expected to register Nikita action in the global registry.
- `masson.search ([string])`  
  List of configuration search path. A search path could be a file or a directory.
- `masson.shell (object)`
  User configuration merged with the shell configuration.
- `masson.shell.name (string)`
  Application name.
- `masson.shell.description (string)`
  Application description.
