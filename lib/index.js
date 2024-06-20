import path from "node:path";
import each from "each";
import { shell } from "shell";
import nikita from "@nikitajs/core";
import { merge } from "mixme";
import multimatch from "multimatch";
import params from "./params.js";
import config_discover from "./config_discover.js";

// Initial parser to extract global options
const args = shell({
  ...params,
  main: {
    name: "main",
  },
}).parse();

// Configuration discovery
const config = await config_discover(args.config);

// Utility functions
const model = {
  nodes: {
    find: ({ fqdn, hostname }) => {
      return config.nodes.filter(
        (node) =>
          (!fqdn || multimatch(node.config.fqdn, fqdn).length) &&
          (!hostname || multimatch(node.config.fqdn, hostname).length)
      );
    },
  },
};

// Nodes normalization
config.nodes = Object.entries(config.nodes).map(([name, node]) => {
  node.name ??= name;
  node.config ??= {};
  node.config.hostname ??= node.config.fqdn?.split(".")[0];
  return node;
});

// Actions normalization
const normalize = (actions, parent = {}) => {
  const names = [];
  return Object.entries(actions).map(([name, action]) => {
    // Properties enrichment
    action.name ??= name;
    action.namespace = [...parent.namespace, action.name];
    action.metadata ??= {};
    // Naming collision assertion
    if (names.includes(action.name)) {
      throw Error(
        `Action already registered, collision name is ${action.name}`
      );
    }
    // Nodes normalization
    if (action.nodes) {
      // Array to object convertion
      action.nodes = Object.fromEntries(
        model.nodes
          .find({ fqdn: [action.nodes].flat(Infinity) })
          .map((node) => [node.name, {}])
      );
    }
    // Children normalization
    const actions = action.actions ? normalize(action.actions, action) : null;
    delete action.actions;
    // Parent property merging
    // Note, metadata.header gets a special treatment
    action = merge(parent, action, {
      metadata: {
        header: [parent.metadata.header, action.metadata.header]
          .flat(Infinity)
          .filter(Boolean),
      },
    });
    return [action, actions];
  });
};
config.actions = normalize(config.actions, { namespace: [], metadata: {} })
  .flat(Infinity)
  .filter(Boolean);

config.masson ??= {}
config.masson.register ??= {}

for(const mod of config.masson.register) {
  await import(mod)
}

await shell({
  ...params,
  commands: {
    check: {
      options: {
        node: {
          shortcut: "n",
          type: "array",
          description: "Filter by fqdn.",
        },
        action: {
          shortcut: "a",
          type: "array",
          description: "Filter by action.",
        },
        module: {
          shortcut: "m",
          type: "array",
          description: "Filter by module.",
        },
        debug: {
          shortcut: "d",
          type: "boolean",
          description: "Activate debug mode.",
        },
        strict: {
          shortcut: "s",
          type: "boolean",
          description: "Stop on error and print its message.",
        },
      },
      handler: async ({ params }) => {
        await each(config.nodes, true, async (node) => {
          const actions = config.actions
            // Filtering leaf actions
            // Note, we might want to support parent actions
            // when a defined handler is present
            // to be injected under the parent property in children,
            // might however be incompatible with sorting.
            .filter( (action) =>
              action.actions
            )
            // Filtering based on parameters
            .filter(
              (action) =>
                // Action node filter
                !!action.nodes?.[node.name] &&
                // Parameters filter `-a --action`
                (!params.action ||
                  multimatch(action.namespace.join("/"), params.action).length) &&
                // Parameters filter `-m --module`
                (!params.module ||
                  multimatch(action.module, params.module).length) &&
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
            if(params.strict){
              action.metadata.relax = false
            }
            app.call(action.module, {
              $: {
                node: node,
                ...action,
              },
            });
          }
          await app;
        });
      },
    },
  },
}).route();
