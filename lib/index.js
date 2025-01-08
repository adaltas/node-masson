import { shell } from "shell";
import { merge } from "mixme";
import configure from "./configure.js";
import route, { params_app } from "./route.js";

export default async function (args, options = {}) {
  // Initial parser to extract global options
  const params = shell({
    ...params_app,
    main: {
      name: "main",
    },
  }).parse(args);
  // Initialize the configuration
  return route(
    args,
    merge(
      {
        config: await configure({ masson: { search: params.config } }),
      },
      options,
    ),
  );
}
