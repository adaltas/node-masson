
import { shell } from "shell";
import params from "./params.js";
import run from "./run.js";
import config_discover from "./config/discover.js";
import config_normalize from "./config/normalize.js";

// Initial parser to extract global options
const args = shell({
  ...params,
  main: {
    name: "main",
  },
}).parse();

// Configuration discovery
const config = await Promise.resolve({ search: args.config })
  .then((config) => config_discover(config))
  .then((config) => config_normalize(config));

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
      handler: async ({ params }) => run({ config, params }),
    },
  },
}).route();
