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
        masson: { log: { cli: false } },
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
        masson: { log: { cli: false } },
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
    it("filter on one command", async function () {
      const config = await configure({
        masson: { log: { cli: false } },
        actions: {
          action_no_command_defined: {
            handler: () => "no",
          },
          action_no_match: {
            commands: "no-match",
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

    it.skip("filter on multiple command", async function () {
      const config = await configure({
        actions: {
          action_no_command_defined: {
            handler: () => "no",
          },
          action_no_match: {
            commands: ["no-match-1", "no-match-2"],
            handler: () => "no",
          },
          action_yes: {
            commands: ["test-1", "test-2"],
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
