
# Action definition

An action in Masson is the basic unit of work. It extends an Nikita actions with additionnal Masson-specific properties.

Common Nikita action properties include:

- `actions.<action>.metadata`   
  Properties available to all actions such as `disabled` or `relax`.
- `actions.<action>.config`   
  Properties specific to an action
- `actions.<action>.module`   
  Module path of the action to execute.

Masson add additionnal properties.

- `actions.<action>.dependencies`
  Actions for which the current action depends on.
- `actions.<action>.masson`
  Properties used by Masson
  - `actions.<action>.masson.namespace`
    Array path of the action.
  - `actions.<action>.masson.slug`   
    String representation of the path
- `actions.<action>.nodes`
  Array of nodes where an action is executed, either locally or on one or multiple SSH nodes.

Dependencies are defined as an object whose keys identify the dependency and whose value defined the dependency properties.

- `actions.<action>.dependencies.required`
- `actions.<action>.dependencies.unique`
- `actions.<action>.dependencies.config`
