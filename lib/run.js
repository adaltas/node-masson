import path from "node:path";
import each from "each";
import { merge } from "mixme";
import nikita from "@nikitajs/core";
import "@nikitajs/log/register";
import multimatch from "multimatch";

export default async (config, options = {}) => {
  options = merge(
    {
      filters: {
        action: undefined,
        module: undefined,
        node: undefined,
      },
    },
    options
  );
  // State
  const state = {};
  // Loop through each node
  return each(
    Object.keys(config.nodes).length ? config.nodes : [null],
    true,
    async (node) => {
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
            (!node || !!action.nodes.includes(node.name)) &&
            // Parameters filter `-a --action`
            (!options.filters.action ||
              multimatch(
                action.masson.namespace.join("/"),
                options.filters.action
              ).length) &&
            // Parameters filter `-m --module`
            (!options.filters.module ||
              multimatch(action.module, options.filters.module).length) &&
            // Parameters filter `-n --node`
            (!node ||
              !options.filters.node ||
              multimatch(node.config.fqdn, options.filters.node).length)
        );
      // Nikita node-based initialization
      const app = nikita({
        $debug: options.debug,
        $if: actions.length,
        $ssh: !node
          ? null
          : {
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
        $if: config.masson.log.cli,
        colors: true,
        host: !node ? "local" : node.name,
        pad: {
          host: 20,
          header: 60,
        },
      });
      // Log storage in Mardown format
      app.log.md({
        $if: config.masson.log.md,
        basedir: path.resolve(process.cwd(), "./logs"),
        filename: `${!node ? "local" : node.name}.md`,
      });
      // Action scheduling
      for (const action of actions) {
        if (options.strict) {
          action.metadata.relax = false;
        }
        app
          .call(action.module, config.masson.nikita, {
            $: false,
            node: node,
            ...action,
          })
          .then((output) => {
            state[`${!node ? "local" : node.name}:/${action.masson.slug}`] = {
              ...action,
              node,
              output,
            };
          });
      }
      await app;
      return state;
    }
  ).then((states) =>
    states.length ? states.reduce((a, b) => ({ ...a, ...b })) : {}
  );
};
