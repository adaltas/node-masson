import { shell } from "shell";
import { merge } from "mixme";
import command_run from "./commands/run.js";
import command_config_show from "./commands/config/show.js";

export const params_app = {
  // name: "masson",
  // description:
  //   "Automatisation for deployment, management and any creazy ideas that comes to mind.",
  options: {
    config: {
      shortcut: "c",
      type: "array",
      description: "Configuration files and directories.",
    },
  },
  commands: {
    config: {
      commands: {
        show: command_config_show,
      },
    },
  },
};

export default async (args, { config, stdout, stderr } = {}) => {
  // Route arguments
  return await shell(
    merge(config.masson.shell, params_app, {
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
      router: { stdout, stderr },
    }),
  ).route(args, config);
};
