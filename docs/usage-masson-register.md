
# Masson action registration

Actions are referenced by their path or by their name in the registry.

Nikita actions are registered by default. Additionnal actions are registered with the `masson.register` property.

The `masson.register` property is an array which accept module path as `string` or an object describing the actions to register.

## Actions registration from module path

A `string` value represent the path of the module to be imported. The discovery follows the [Node.js module discovery](https://nodejs.org/api/modules.html#loading-from-node_modules-folders). The module is loaded from the "node_modules" folder unless it begins with '/', '../', or './'.

```yaml
masson:
  register:
    - @org/my_app/register
```

In this example, the `register` module is loaded. It uses the Nikita `registry.register` function to register actions in the statically. Every instance of Nikita have the registered actions available.

This is an example of such a module.

```js
// Dependencies
import "@nikitajs/network/register";
import registry from "@nikitajs/core/registry";
// Action registration
await registry.register({
  my_app: {
    user: {
      "": "@org/my_app/user/create",
      disable: "@org/my_app/user/disable",
      enable: "@org/my_app/user/enable",
      exists: "@org/my_app/user/exists",
      list: "@org/my_app/user/list",
    },
  },
});
```

## Actions registration from object

An `object` value register the action. Keys represent the action's namespace. Values are the module paths of the actions definitions.

```yaml
masson:
  register:
    - my_app:
        user:
          "":      "./lib/actions/user/create.js",
          disable: "./lib/actions/user/disable.js",
          enable:  "./lib/actions/user/enable.js",
          exists:  "./lib/actions/user/exists.js",
          list:    "./lib/actions/user/list.js",
```

In the above example, new actions are registered, for example `nikita.my_app.user(...)` and `nikita.my_app.user.list(...)`.
