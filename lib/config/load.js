import path from "path";
import fs from "fs/promises";
import { merge } from "mixme";
import load from "masson/utils/load"

export default async function (paths) {
  var file, files, i, j, k, len, len1, location, ref, stat, v;
  // Load configuration
  const configs = [];
  for (i = 0, len = paths.length; i < len; i++) {
    const config = paths[i];
    location = `${path.resolve(process.cwd(), config)}`;
    stat = await fs.stat(location);
    if (stat.isDirectory()) {
      files = await fs.readdir(location);
      for (j = 0, len1 = files.length; j < len1; j++) {
        file = files[j];
        if (file.indexOf(".") === 0) {
          continue;
        }
        file = `${path.resolve(location, file)}`;
        stat = await fs.stat(file);
        if (stat.isDirectory()) {
          continue;
        }
        configs.push(await load(file));
      }
    } else {
      configs.push(await load(location));
    }
  }
  const config = merge(...configs);
  ref = config.servers;
  for (k in ref) {
    v = ref[k];
    if (v.host == null) {
      v.host = k;
    }
    if (v.shortname == null) {
      v.shortname = k.split(".")[0];
    }
    v;
  }
  return config;
}
