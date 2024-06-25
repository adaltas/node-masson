
import { merge } from "mixme";
import multimatch from "multimatch";

// Utility functions
const model = (config) => ({
  nodes: {
    find: ({ fqdn, hostname }) => {
      return config.nodes.filter(
        (node) =>
          (!fqdn || multimatch(node.config.fqdn, fqdn).length) &&
          (!hostname || multimatch(node.config.fqdn, hostname).length)
      );
    },
  },
});

export default (config = {}) => {
  // Nodes normalization
  config.nodes = Object.entries(config.nodes || {}).map(([name, node]) => {
    node.name ??= name;
    node.config ??= {};
    node.config.hostname ??= node.config.fqdn?.split(".")[0];
    return node;
  });
  // Actions normalization
  const normalize = (actions = {}, parent = {}) => {
    return Object.entries(actions).map(([name, action]) => {
      // Properties enrichment
      action.name ??= name;
      action.namespace = [...parent.namespace, action.name];
      action.metadata ??= {};
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
  config.actions = normalize(config.actions, { namespace: [], metadata: {} })
    .flat(Infinity)
    .filter(Boolean);
  return config
}
