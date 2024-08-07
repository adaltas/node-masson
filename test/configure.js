import "@nikitajs/file/register";
import configure from "../lib/configure.js";

describe("config.discover", () => {
  it("default without arguments", async () => {
    await configure().should.finally.eql({
      nodes: [],
      masson: { nikita: { $: false }, register: [] },
      actions: [],
    });
  });
});
