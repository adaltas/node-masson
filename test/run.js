import configure from "../lib/configure.js";
import run from "../lib/run.js";

describe("config.run", () => {
  it("default without arguments", async () => {
    const config = await configure();
    await run(config).should.finally.eql({});
  });
  it("one action with local node", async () => {
    const config = await configure({
      nodes: {
        local: {},
      },
      actions: {
        action_1: {
          nodes: "*",
          handler: () => 1,
        },
      },
    });
    await run(config).then((action) => {
      action["local://action_1"].should.match({
        node: {
          name: "local",
        },
        output: 1,
      });
    });
  });
});
