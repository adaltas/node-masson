import fs from "node:fs/promises";
import path from "node:path";
import each from "each";
import { merge } from "mixme";
import { parse } from "yaml";
import { glob } from "glob";
import { insert } from "@nikitajs/utils/object";

// Temporary function to be replaced by
// ```
// await import(file, {
//   with: { type: "json" },
// }).then(({ default: d }) => d)
// ```
// See https://github.com/eslint/eslint/discussions/15305#discussioncomment-1634740
const read_json = async (module) => {
  const fileUrl = new URL(module, import.meta.url);
  return JSON.parse(await fs.readFile(fileUrl, "utf8"));
};

/**
 * Configuration Discovery:
 * - discover file and directories
 * - load the files
 * - merge their content
 * - return the merged object
 */
export default async ({
  search = [],
  patterns = ["**/*.yml", "**/*.yaml", "**/*.js", "**/*.json"],
}) => {
  // Normalize argument
  if (!Array.isArray((search = [search]))) {
    search = [search];
  }
  // Merge all configuration toguether
  return merge(
    ...(
      await each(search, (search) => {
        // Filter discovery by file extensions
        return glob(patterns, {
          cwd: search,
        }).then((files) =>
          each(files, async (file) => {
            const dirname = path.dirname(file);
            // Split filename and extract extension
            const basenames = path.basename(file).split(".");
            const extension = basenames.pop();
            file = path.resolve(search, file);
            // Load by file formats
            const config =
              extension === "js"
                ? await import(file).then(({ default: d }) => d)
                : extension === "json"
                ? await read_json(file)
                : await fs.readFile(file, "utf8").then((data) => parse(data));
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
