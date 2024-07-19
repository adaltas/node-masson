import fs from "node:fs/promises";
import path from "node:path";
import yaml from "yaml";
import { is_object_literal } from "mixme";

export default async function mklayout(pages, handler) {
  // Prepare
  const rand = String(Math.random()).substring(2);
  const tmpdir = path.resolve(`.test/redac-test-yaml-enrich-${rand}`);
  await fs.rm(tmpdir, { recursive: true }).catch(() => {});
  await fs.mkdir(`${tmpdir}`, { recursive: true });
  // Write
  for (let [location, content, metadata] of pages) {
    const path_relative = path.resolve(tmpdir, location);
    await fs.mkdir(path.dirname(path_relative), { recursive: true });
    const frontmatter = metadata
      ? `---\n${yaml.stringify(metadata)}\n---\n\n`
      : "";
    if (location.endsWith(".json") && is_object_literal(content)) {
      content = JSON.stringify(content, null, 2);
    }
    content = content.replace("{{tmpdir}}", tmpdir);
    await fs.writeFile(
      path_relative,
      frontmatter +
        (content || "") +
        ((content || "").endsWith("\n") ? "" : "\n")
    );
  }
  try {
    // Run
    if (handler) {
      return await handler(tmpdir);
    }
  } finally {
    // Dispose
    await fs.rm(tmpdir, { recursive: true });
  }
}
