import path from "node:path/posix";
import { merge } from "mixme";
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
          multimatch(node.name || "", name).length
      );
    },
  },
});

export default async (config = {}) => {
  // Nodes normalization
  config.nodes = Object.entries(config.nodes || {}).map(([name, node]) => {
    node.name ??= name;
    node.config ??= {};
    node.config.hostname ??= node.config.fqdn?.split(".")[0];
    return node;
  });
  // Masson normalization
  config.masson ??= {};
  config.masson.register ??= [];
  for (let mod of config.masson.register) {
    if (mod.startsWith(".")) {
      mod = path.resolve(process.cwd(), mod);
    }
    await import(mod);
  }
  // Actions normalization
  const normalize = (actions = {}, parent = {}) => {
    return Object.entries(actions).map(([name, action]) => {
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
      if (action.nodes) {
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
      });
      // Child actions erasure
      delete action.actions;
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
