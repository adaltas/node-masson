import { stringify } from "yaml";

export default {
  options: {
    format: {
      default: "yaml",
      description: "Output format.",
      enum: ["json"],
      shortcut: "f",
      type: "string",
    },
  },
  handler: async ({ params, stdout }, config) => {
    switch (params.format) {
      case "json":
        stdout.write(JSON.stringify(config, 2, true));
        break;
      case "yaml":
        stdout.write(stringify(config));
        break;
    }
  },
};
