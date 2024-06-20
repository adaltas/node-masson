import fs from "node:fs/promises";
import path from "node:path";
import each from "each";
import { merge } from "mixme";
import { parse } from "yaml";
import { glob } from "glob";
import { insert } from "@nikitajs/utils/object"

export default async (searchs) => {
  return merge(
    ...(
      await each(searchs, (search) => {
        // try `*.y?(x)ml`
        return glob(["**/*.yml", "**/*.yaml"], { cwd: search }).then((files) =>
          each(files, async (file) => {
            const dirname = path.dirname(file);
            const basename = path.basename(file);
            const config = await fs
              .readFile(path.resolve(search, file), "utf8")
              .then((data) => parse(data));
            const root = [
              ...dirname.split(path.sep),
              ...basename.split(".").slice(0, -1),
            ].filter((dir) => dir !== ".");
            const res = insert({}, root, config)
            return res
          })
        );
      })
    ).flat(Infinity)
  );
};
