import dedent from "dedent";
import registry from "@nikitajs/core/registry";
import "@nikitajs/file/register";
import normalize from "../../lib/config/normalize.js";
import mklayout from "../../lib/utils/mklayout.js";

describe("config.normalize", function () {
  it("default without arguments", async function () {
    await normalize().should.finally.eql({
      nodes: [],
      masson: {
        commands: {},
        log: { cli: true, md: false },
        nikita: { $: false },
        register: [],
      },
      actions: [],
    });
  });

  describe("nodes", function () {
    it("name default to key", async function () {
      await normalize({
        nodes: {
          node_1: {},
          node_2: {},
        },
      })
        .then(({ nodes }) => nodes)
        .should.finally.eql([
          { name: "node_1", config: { hostname: undefined } },
          { name: "node_2", config: { hostname: undefined } },
        ]);
    });
  });

  describe("masson.commands", function () {
    it("default normalization", async function () {
      await normalize()
        .then((config) => config.masson.commands)
        .should.finally.eql({});
    });

    it("enrich during action discovery", async function () {
      await normalize({
        actions: {
          action_cmd_1: {
            commands: "cmd_1",
          },
          action_cmd_2: {
            commands: ["cmd_2"],
          },
        },
      })
        .then((config) => config.masson.commands)
        .should.finally.eql({
          cmd_1: {},
          cmd_2: {},
        });
    });
  });

  describe("masson.log", function () {
    it("default normalization", async function () {
      await normalize()
        .then((config) => config.masson.log)
        .should.finally.eql({ cli: true, md: false });
    });
  });

  describe("masson.nikita", function () {
    it("default normalization", async function () {
      await normalize()
        .then((config) => config.masson.nikita)
        .should.finally.eql({ $: false });
    });
  });

  describe("masson.register", function () {
    it("load module when defined as string", async function () {
      await mklayout(
        [
          ["./package.json", { type: "module" }],
          [
            "./register.js",
            dedent`
              // Dependencies
              import registry from "@nikitajs/core/registry";
              // Action registration
              await registry.register({
                masson_test: "{{tmpdir}}/test.js",
              });
              `,
          ],
          ["./test.js", 'export default () => "ok"'],
        ],
        async (tmpdir) => {
          await normalize({
            masson: {
              register: [`${tmpdir}/register.js`],
            },
          });
          const actions = await registry.get();
          actions.masson_test[""].metadata.module.should.eql(
            `${tmpdir}/test.js`,
          );
        },
      );
    });

    it("merge with the nikita default action when an object", async function () {
      await normalize({
        masson: {
          register: [
            {
              an: { action: () => {} },
            },
          ],
        },
      })
        .then((config) => config.masson.nikita.metadata.register)
        .should.finally.eql({ an: { action: () => {} } });
    });
  });

  describe("actions", function () {
    it("root actions no children", async function () {
      await normalize({
        actions: {
          action_1: {},
          action_2: {},
        },
      })
        .then(({ actions }) =>
          actions.map(({ actions, masson, metadata }) => ({
            actions,
            masson,
            metadata,
          })),
        )
        .should.finally.eql([
          {
            actions: [],
            masson: {
              name: "action_1",
              namespace: ["action_1"],
              slug: "/action_1",
            },
            metadata: { header: [] },
          },
          {
            actions: [],
            masson: {
              name: "action_2",
              namespace: ["action_2"],
              slug: "/action_2",
            },
            metadata: { header: [] },
          },
        ]);
    });

    it("deep actions", async function () {
      await normalize({
        // prettier-ignore
        actions: {
          action_1: {
            actions: {
              action_1_1: {
                actions: {
                  action_1_1_1: {}}}}},
          action_2: {
            actions: {
              action_2_1: {}}}},
      })
        .then(({ actions }) =>
          actions.map(({ actions, masson, metadata }) => ({
            actions,
            masson,
            metadata,
          })),
        )
        .should.finally.eql([
          {
            actions: [["action_1", "action_1_1"]],
            masson: {
              name: "action_1",
              namespace: ["action_1"],
              slug: "/action_1",
            },
            metadata: { header: [] },
          },
          {
            actions: [["action_1", "action_1_1", "action_1_1_1"]],
            masson: {
              name: "action_1_1",
              namespace: ["action_1", "action_1_1"],
              slug: "/action_1/action_1_1",
            },
            metadata: { header: [] },
          },
          {
            actions: [],
            masson: {
              name: "action_1_1_1",
              namespace: ["action_1", "action_1_1", "action_1_1_1"],
              slug: "/action_1/action_1_1/action_1_1_1",
            },
            metadata: { header: [] },
          },
          {
            actions: [["action_2", "action_2_1"]],
            masson: {
              name: "action_2",
              namespace: ["action_2"],
              slug: "/action_2",
            },
            metadata: { header: [] },
          },
          {
            actions: [],
            masson: {
              name: "action_2_1",
              namespace: ["action_2", "action_2_1"],
              slug: "/action_2/action_2_1",
            },
            metadata: { header: [] },
          },
        ]);
    });
  });

  describe("actions.commands", function () {
    it("default", async function () {
      await normalize({
        actions: {
          my_action: {},
        },
      }).then(({ actions }) => {
        actions.should.match([
          {
            masson: {
              name: "my_action",
            },
            commands: [],
          },
        ]);
      });
    });

    it("normalize command to an array", async function () {
      await normalize({
        actions: {
          my_action: {
            commands: "test",
          },
        },
      }).then(({ actions }) => {
        actions.should.match([
          {
            masson: {
              name: "my_action",
            },
            commands: ["test"],
          },
        ]);
      });
    });
  });

  describe("actions.nodes", function () {
    it("not defined", async function () {
      await normalize({
        // prettier-ignore
        nodes:{
          node_1: { config: { hostname: 'node_1' }},
          node_2 : {}},
        actions: {
          action_1: {},
        },
      })
        .then(({ actions }) => actions.shift())
        .then(({ nodes }) => nodes)
        .should.finally.eql([]);
    });

    it("string match all", async function () {
      await normalize({
        // prettier-ignore
        nodes: {
          node_1: { config: { hostname: 'node_1' }},
          node_2 : {}},
        actions: {
          action_1: {
            nodes: "*",
          },
        },
      })
        .then(({ actions }) => actions.shift())
        .then((action) => action.nodes.should.eql(["node_1", "node_2"]));
    });

    it("array match nodes.<node>.name and nodes.<node>.config.[hostname,fqdn]", async function () {
      await normalize({
        // prettier-ignore
        nodes: {
          node_1: { config: { hostname: 'node_1' }},
          node_2: { config: { fqdn: 'node_2.domain.com' }},
          node_3: {},
          invalid_node: {}},
        actions: {
          action_1: {
            nodes: ["node_*"],
          },
        },
      })
        .then(({ actions }) => actions.shift())
        .then((action) =>
          action.nodes.should.eql(["node_1", "node_2", "node_3"]),
        );
    });
  });
});
