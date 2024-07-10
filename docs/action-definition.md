
# Action definition

An action is a Nikita action with additionnal Masson related properties.

Common Nikita action properties include:

- `metadata` Properties available to all actions such as `disabled` or `relax`.
- `config` Properties specific to an action
- `module` Module path of the action to execute.

Masson add additionnal properties.
- `masson` Properties used by Masson
  - `namespace` Array path of the action.
  - `slug` String representation of the path

