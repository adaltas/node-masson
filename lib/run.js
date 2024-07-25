import path from "node:path";
import each from "each";
import nikita from "@nikitajs/core";
import multimatch from "multimatch";

export default async ({ config, params }) => {
  await each(config.nodes, true, async (node) => {
    const actions = config.actions
      // Filtering leaf actions
      // Note, we might want to support parent actions
      // when a defined handler is present
      // to be injected under the parent property in children,
      // might however be incompatible with sorting.
      .filter((action) => action.actions.length === 0)
      // Filtering based on parameters
      .filter(
        (action) =>
          // Action node filter
          !!action.nodes.includes(node.name) &&
          // Parameters filter `-a --action`
          (!params.action ||
            multimatch(action.masson.namespace.join("/"), params.action)
              .length) &&
          // Parameters filter `-m --module`
          (!params.module || multimatch(action.module, params.module).length) &&
          // Parameters filter `-n --node`
          (!params.node || multimatch(node.config.fqdn, params.node).length)
      );
    // Nikita node-based initialization
    const app = nikita({
      $debug: params.debug,
      $if: actions.length,
      $ssh: {
        ip: node.ip ?? node.config.fqdn ?? node.config.hostname,
        username: node.config.username,
        private_key_path: "~/.ssh/id_ed25519",
      },
      $sudo: true,
      ...config,
    });
    // Register quick/temporary secret plugins
    app.plugins.register({
      name: "masson/secrets",
      hooks: {
        "nikita:action": {
          before: "@nikitajs/core/plugins/templated",
          handler: (action) => {
            action.secrets = config.secrets;
          },
        },
      },
    });
    // Report process to the CLI
    app.log.cli({
      colors: true,
      host: node.name,
      pad: {
        host: 20,
        header: 60,
      },
    });
    // Log storage in Mardown format
    app.log.md({
      basedir: path.resolve(process.cwd(), "./logs"),
      filename: `${node.name}.md`,
    });
    // Action scheduling
    for (const action of actions) {
      if (params.strict) {
        action.metadata.relax = false;
      }
      app.call(action.module, config.masson.nikita, {
        $: false,
        node: node,
        ...action,
      });
    }
    await app;
  });
};
