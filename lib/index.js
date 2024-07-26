import { shell } from "shell";
import params from "./params.js";
import configure from "./configure.js";
import run from "./run.js";

// Initial parser to extract global options
const args = shell({
  ...params,
  main: {
    name: "main",
  },
}).parse();

const config = await configure({ masson: { search: args.config } });

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
        mutate(config, {
          masson: { log: { cli: true } },
        });
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
    },
  },
}).route();
