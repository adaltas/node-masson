import nikita from "@nikitajs/core";
import "@nikitajs/file/register";
import discover from "../../lib/config/discover.js";

describe("config.discover", function () {
  describe("structure", function () {
    it("load composite filenames", async function () {
      await nikita(
        {
          $tmpdir: true,
        },
        async function ({ metadata: { tmpdir } }) {
          await this.file.yaml({
            target: `${tmpdir}/conf/actions.service.actions.component_1.yml`,
            content: { config: { test: "test 1" } },
          });
          await this.file.yaml({
            target: `${tmpdir}/conf/actions.service.actions.component_2.yaml`,
            content: { config: { test: "test 2" } },
          });
          // prettier-ignore
          return discover({ search: `${tmpdir}/conf` })
            .should.finally.eql({
              actions: { service: { actions: {
                component_1: { config: { test: "test 1" } },
                component_2: { config: { test: "test 2" } }}}}});
        }
      );
    });

    it("load composite directories", async function () {
      await nikita(
        {
          $tmpdir: true,
        },
        async function ({ metadata: { tmpdir } }) {
          await this.file.yaml({
            target: `${tmpdir}/conf/actions.service.actions/component_1.yml`,
            content: { config: { test: "test 1" } },
          });
          await this.file.yaml({
            target: `${tmpdir}/conf/actions.service.actions/component_2.yaml`,
            content: { config: { test: "test 2" } },
          });
          // prettier-ignore
          await discover({search: `${tmpdir}/conf`})
            .should.finally.eql({
              actions: { service: { actions:{
                component_1: { config: { test: 'test 1' }},
                component_2: { config: { test: 'test 2' }}}}}})
        }
      );
    });
  });

  describe("load", function () {
    it("yaml", async function () {
      await nikita(
        {
          $tmpdir: true,
        },
        async function ({ metadata: { tmpdir } }) {
          await this.file.yaml({
            target: `${tmpdir}/conf/actions.yml`,
            content: { component_1: { config: { test: "test 1" } } },
          });
          // prettier-ignore
          await discover({ search: `${tmpdir}/conf`})
          .should.finally.eql({
            actions: {
              component_1: { config: { test: 'test 1' }}}})
        }
      );
    });

    it("js ESM", async function () {
      await nikita(
        {
          $tmpdir: true,
        },
        async function ({ metadata: { tmpdir } }) {
          await this.file.json({
            target: `${tmpdir}/package.json`,
            content: { type: "module" },
          });
          await this.file({
            target: `${tmpdir}/conf/actions.js`,
            content:
              "export default { component_1: { config: { test: 'test 1' } } }",
          });
          // prettier-ignore
          await discover ({search: `${tmpdir}/conf`})
          .should.finally.eql({
            actions: {
              component_1: { config: { test: 'test 1' }}}})
        }
      );
    });

    it("js CommonJS", async function () {
      await nikita(
        {
          $tmpdir: true,
          $dirty: true,
        },
        async function ({ metadata: { tmpdir } }) {
          await this.file({
            target: `${tmpdir}/conf/actions.js`,
            content:
              "module.exports = { component_1: { config: { test: 'test 1' } } }",
          });
          // prettier-ignore
          await discover({search: `${tmpdir}/conf`})
          .should.finally.eql({
            actions: {
              component_1: { config: { test: 'test 1' }}}})
        }
      );
    });

    it("json", async function () {
      await nikita(
        {
          $tmpdir: true,
          $dirty: true,
        },
        async function ({ metadata: { tmpdir } }) {
          await this.file.json({
            target: `${tmpdir}/conf/actions.json`,
            content: { component_1: { config: { test: "test 1" } } },
          });
          // prettier-ignore
          await discover ({search: `${tmpdir}/conf`})
          .should.finally.eql({
            actions:{
              component_1: { config: { test: 'test 1' }}}})
        }
      );
    });
  });
});
