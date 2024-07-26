import config_discover from "./config/discover.js";
import config_normalize from "./config/normalize.js";

export default async (config = {}) => {
  return await Promise.resolve(config)
    .then((config) => config_discover(config))
    .then((config) => config_normalize(config));
};
