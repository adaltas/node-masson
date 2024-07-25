
## Actions

Actions are declared inside the `actions` configuration property. 

An action respects the Nikita action format. In the configuration, it uses the long format definition, for example `{ metadata: { header: "My Service" }, config: { key: "value"}}`.

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
