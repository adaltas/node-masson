
# CLI usage

Run all actions of a command.

```bash
npx masson -c <conf> <command>
```

Run a command with module and node filtering.

```bash
npx masson -c <conf> <command> -n 'master-*' -m './lib/check-*' 
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
