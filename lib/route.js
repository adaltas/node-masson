import { shell } from "shell";
import command_run from "./commands/run.js";

export const params_app = {
  name: "masson",
  description:
    "Automatisation for deployment, management and any creazy ideas that comes to mind.",
  options: {
    config: {
      shortcut: "c",
      type: "array",
      description: "Configuration files and directories.",
    },
  },
};

export default async (config, args) => {
  // Route arguments
  return await shell({
    ...params_app,
    commands: {
      run: !Object.keys(config.masson.commands).length
        ? {
            config: config,
            ...command_run,
          }
        : {
            commands: Object.fromEntries(
              Object.entries(config.masson.commands).map(([command]) => [
                command,
                {
                  config: config,
                  ...command_run,
                },
              ]),
            ),
          },
    },
  }).route(args, config);
};
