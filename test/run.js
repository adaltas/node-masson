import configure from "../lib/configure.js";
import run from "../lib/run.js";
import should from "should";

describe("config.run", function () {
  it("default without arguments", async function () {
    const config = await configure();
    await run(config).should.finally.eql({});
  });

  describe("node", function () {
    it("one action without node", async function () {
      const config = await configure({
        actions: {
          action_1: {
            handler: () => 1,
          },
        },
      });
      await run(config).then((action) => {
        action["local://action_1"].should.match({
          output: 1,
        });
      });
    });

    it("one action with local node", async function () {
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

  describe("command", function () {
    it("filter based on one command", async function () {
      const config = await configure({
        actions: {
          action_no: {
            handler: () => "no",
          },
          action_yes: {
            commands: "test",
            handler: () => "yes",
          },
        },
      });
      await run(config, { command: "test" }).then((action) => {
        should(action["local://action_no"]).be.undefined();
        action["local://action_yes"].should.match({
          output: "yes",
        });
      });
    });
  });
});
