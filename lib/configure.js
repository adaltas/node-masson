import config_discover from "./config/discover.js";
import config_normalize from "./config/normalize.js";

export default async ({ search } = {}) => {
  return await Promise.resolve({ search: search })
    .then((config) => config_discover(config))
    .then((config) => config_normalize(config));
};
