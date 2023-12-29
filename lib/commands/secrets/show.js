var secrets, yaml;

secrets = require("masson/secrets");

yaml = require("js-yaml");

import util from "node:util";

export default async function ({ params }, config) {
  var MAX_LENGTH, data, err, output, reduceSize, store;
  // if the size of a password is > MAX_LENGTH chars,
  // replace the password inplace in the given object
  MAX_LENGTH = 40; // max password length to be displayed
  reduceSize = function (obj) {
    var k, results, v;
    results = [];
    for (k in obj) {
      v = obj[k];
      if (typeof v === "string" && v.length > MAX_LENGTH) {
        obj[k] = v.substring(0, MAX_LENGTH) + "...";
      }
      if (typeof v === "object") {
        results.push(reduceSize(v));
      } else {
        results.push(void 0);
      }
    }
    return results;
  };
  store = secrets(params);
  if (!(await store.exists())) {
    return process.stderr.write(
      [
        "Store does not exists, ",
        "run the `init` command to initialize it.\n",
      ].join("")
    );
  }
  try {
    data = await store.get();
    if (process.stdin.isTTY && params.full == null) {
      reduceSize(data);
    }
    output = (function () {
      switch (params.format) {
        case "json":
          return JSON.stringify(data);
        case "prettyjson":
          return util.inspect(data, {
            colors: process.stdout.isTTY,
            depth: 2e308,
          });
        case "yaml":
          return yaml.dump(data);
      }
    })();
    return process.stdout.write(`${output}` + "\n");
  } catch (error) {
    err = error;
    return process.stderr.write(`${err.message}` + "\n");
  }
}
