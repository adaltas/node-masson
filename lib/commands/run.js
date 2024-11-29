import run from "../run.js";

export default {
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
  handler: async ({ params }, config) => {
    return run(config, {
      filters: {
        node: params.node,
        action: params.action,
        module: params.module,
      },
      debug: params.debug,
      strict: params.strict,
    });
  },
};
