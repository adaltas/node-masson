import "@nikitajs/file/register";
import cli from "../lib/index.js";
import mklayout from "../lib/utils/mklayout.js";

describe("cli", function () {
  it("default with no config and no arguments", async function () {
    await mklayout(
      [
        [
          "./conf/actions.js",
          "export default { action_cmd_1: { commands: 'cmd_1', handler: () => 1} }",
        ],
      ],
      async (tmpdir) => {
        await cli(["-c", `${tmpdir}/conf`, "run", "cmd_1"], {
          config: {
            masson: {
              log: {
                cli: false,
              },
            },
          },
        }).should.finally.match({
          "local://action_cmd_1": {
            masson: {
              namespace: [Array],
              name: "action_cmd_1",
              slug: "/action_cmd_1",
            },
            metadata: { header: [] },
            commands: ["cmd_1"],
            handler: (it) => it.should.be.Function(),
            nodes: [],
            actions: [],
            node: null,
            output: 1,
          },
        });
      },
    );
  });
});
