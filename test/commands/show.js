import { Writable } from "node:stream";
import dedent from "dedent";
import "@nikitajs/file/register";
import cli from "../../lib/index.js";
import mklayout from "../../lib/utils/mklayout.js";

describe("config.discover", function () {
  it("default to yaml", async function () {
    await mklayout(
      [["./conf/masson.js", "export default { shell: { name: 'catchme' } }"]],
      async (tmpdir) => {
        let config;
        await cli(["-c", `${tmpdir}/conf`, "config", "show"], {
          stdout: new Writable({
            write: function (data) {
              config = data.toString();
            },
          }),
        });
        config.should.eql(
          dedent`
          masson:
            search:
              - ${tmpdir}/conf
            patterns:
              - "**/*.yml"
              - "**/*.yaml"
              - "**/*.js"
              - "**/*.json"
            shell:
              name: catchme
              description: Automatisation for deployment, management and any creazy ideas that
                comes to mind.
            commands: {}
            log:
              cli: true
              md: false
            nikita:
              $: false
            register: []
          nodes: []
          actions: []
        ` + "\n",
        );
        // config.masson.shell.name.should.eql("catchme");
      },
    );
  });

  it("format json", async function () {
    await mklayout(
      [["./conf/masson.js", "export default { shell: { name: 'catchme' } }"]],
      async (tmpdir) => {
        let config;
        await cli(
          ["-c", `${tmpdir}/conf`, "config", "show", "--format", "json"],
          {
            stdout: new Writable({
              write: function (data) {
                config = JSON.parse(data.toString(), null, 2);
              },
            }),
          },
        );
        config.should.match({
          masson: {
            search: [`${tmpdir}/conf`],
            patterns: ["**/*.yml", "**/*.yaml", "**/*.js", "**/*.json"],
            shell: {
              name: "catchme",
              description:
                "Automatisation for deployment, management and any creazy ideas that comes to mind.",
            },
            commands: {},
            log: { cli: true, md: false },
            nikita: { $: false },
            register: [],
          },
          nodes: [],
          actions: [],
        });
      },
    );
  });
});
