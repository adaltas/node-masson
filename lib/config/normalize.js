import path from "node:path/posix";
import { is_object_literal, merge, mutate } from "mixme";
import multimatch from "multimatch";

// Utility functions
const model = (config) => ({
  nodes: {
    find: ({ fqdn, hostname, name }) => {
      return config.nodes.filter(
        (node) =>
          !fqdn ||
          multimatch(node.config.fqdn || "", fqdn).length ||
          !hostname ||
          multimatch(node.config.hostname || "", hostname).length ||
          !name ||
          multimatch(node.name || "", name).length,
      );
    },
  },
});

export default async (config = {}) => {
  // Immutable
  config = merge(config);
  // Nodes normalization
  config.nodes = Object.entries(config.nodes || {}).map(([name, node]) => {
    node.name ??= name;
    node.config ??= {};
    const hostname = node.config.fqdn?.split(".")[0];
    if (hostname) node.config.hostname = hostname;
    const host = node.config.ip ?? node.config.fqdn ?? node.config.hostname;
    if (host) node.config.host = host;
    return node;
  });
  // Masson normalization
  config.masson ??= {};
  // Command normalization
  config.masson.commands ??= {};
  // Masson log
  config.masson.log ??= {};
  config.masson.log.cli ??= true;
  config.masson.log.md ??= false;
  // Masson Nikita
  config.masson.nikita ??= {};
  mutate(config.masson.nikita, { $: false });
  // Masson Register
  config.masson.register ??= [];
  for (let mod of config.masson.register) {
    if (typeof mod === "string") {
      if (mod.startsWith(".")) {
        mod = path.resolve(process.cwd(), mod);
      }
      await import(mod);
    } else if (is_object_literal(mod)) {
      mutate(config.masson.nikita, { metadata: { register: mod } });
    }
  }
  // Actions normalization
  const normalize = (actions = {}, parent = {}) => {
    return Object.entries(actions).map(([name, action]) => {
      // Command normalization
      action.commands ??= [];
      if (!Array.isArray(action.commands)) {
        action.commands = [action.commands];
      }
      action.commands.map((command) => {
        config.masson.commands[command] ??= {};
      });
      // Properties enrichment
      action.masson ??= {};
      action.masson.name ??= name;
      action.masson.namespace = [
        ...parent.masson.namespace,
        action.masson.name,
      ].filter(Boolean);
      action.masson.slug = path.join("/", ...action.masson.namespace);
      action.metadata ??= {};
      // Nodes normalization
      if (!action.nodes) {
        action.nodes = [];
      } else {
        // Array to object convertion
        // Nodes are defined as an array and
        // converted to an object whose key is the node's name
        action.nodes = model(config)
          .nodes.find({
            fqdn: [action.nodes].flat(Infinity),
            hostname: [action.nodes].flat(Infinity),
            name: [action.nodes].flat(Infinity),
          })
          .map((node) => node.name);
      }
      // Children normalization
      const actions = action.actions ? normalize(action.actions, action) : null;
      // Parent property merging
      // Note, metadata.header gets a special treatment
      action = merge(parent, action, {
        metadata: {
          header: [parent.metadata.header, action.metadata.header]
            .flat(Infinity)
            .filter(Boolean),
        },
        actions: !action.actions
          ? []
          : Object.keys(action.actions).map((name) => [
              ...action.masson.namespace,
              name,
            ]),
      });
      return [action, actions];
    });
  };
  config.actions = normalize(config.actions, {
    masson: { namespace: [] },
    metadata: {},
  })
    .flat(Infinity)
    .filter(Boolean);
  return config;
};
