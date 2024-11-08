import "@nikitajs/file/register";
import configure from "../lib/configure.js";

describe("config.discover", function () {
  it("default without arguments", async function () {
    await configure().should.finally.eql({
      nodes: [],
      masson: {
        nikita: { $: false },
        patterns: ["**/*.yml", "**/*.yaml", "**/*.js", "**/*.json"],
        register: [],
        search: [],
      },
      actions: [],
    });
  });
});
