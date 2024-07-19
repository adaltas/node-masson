import fs from "node:fs/promises";
import path from "node:path";
import each from "each";
import { merge } from "mixme";
import { parse } from "yaml";
import { glob } from "glob";
import { insert } from "@nikitajs/utils/object";

/**
 * Configuration Discovery:
 * - discover file and directories
 * - load the files
 * - merge their content
 * - return the merged object
*/
export default async ({
  searchs = [],
  patterns = ["**/*.yml", "**/*.yaml", "**/*.js", "**/*.json"],
}) => {
  // Normalize argument
  if (!Array.isArray((searchs = [searchs]))) {
    searchs = [searchs];
  }
  // Merge all configuration toguether
  return merge(
    ...(
      await each(searchs, (search) => {
        // Filter discovery by file extensions
        return glob(patterns, {
          cwd: search,
        }).then((files) =>
          each(files, async (file) => {
            const dirname = path.dirname(file);
            // Split filename and extract extension
            const basenames = path.basename(file).split(".");
            const extension = basenames.pop();
            // Load by file formats
            const config =
              extension === "js"
                ? await import(path.resolve(search, file)).then(
                    ({ default: d }) => d
                  )
                : extension === "json"
                ? await import(path.resolve(search, file), {
                    with: { type: "json" },
                  }).then(({ default: d }) => d)
                : await fs
                    .readFile(path.resolve(search, file), "utf8")
                    .then((data) => parse(data));
            // Build the tree path
            const root = [
              ...dirname
                .split(path.sep)
                .map((dir) => dir.split("."))
                .flat(Infinity)
                .filter(Boolean),
              ...basenames,
            ];
            // Insert config into the tree before merging
            const res = insert({}, root, config);
            return res;
          })
        );
      })
    ).flat(Infinity)
  );
};
