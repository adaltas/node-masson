import "@nikitajs/file/register";
import configure from "../lib/configure.js";

describe("configure", function () {
  it("default without arguments", async function () {
    await configure().should.finally.eql({
      nodes: [],
      masson: {
        commands: {},
        log: { cli: true, md: false },
        nikita: { $: false },
        patterns: ["**/*.yml", "**/*.yaml", "**/*.js", "**/*.json"],
        register: [],
        search: [],
      },
      actions: [],
    });
  });
});
