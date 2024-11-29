import { shell } from "shell";
import configure from "./configure.js";
import route, { params_app } from "./route.js";

export default async function (args) {
  // Initial parser to extract global options
  const params = shell({
    ...params_app,
    main: {
      name: "main",
    },
  }).parse(args);
  // Initialize the configuration
  const config = await configure({ masson: { search: params.config } });
  return route(config, args);
}
