
# Masson definition

Masson properties alter the global behavior of Masson.

It consists of the following properties.

- `register`  
  An array of instructions to register Nikita actions. Objects map keys representing the action's namespaces to values representing the action definition. When defined as an object, actions are registered inside Nikita sessions. A string represents the module name which is expected to register Nikita action in the global registry.
- `nikita`
  Default properties applied to all actions.
