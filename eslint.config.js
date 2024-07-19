import globals from "globals";
import pluginJs from "@eslint/js";
import eslintConfigPrettier from "eslint-config-prettier";

export default [
  {
    languageOptions: { globals: { ...globals.node } },
    rules: {
      // See https://eslint.org/docs/latest/rules/indent
      indent: [
        "error",
        2,
        {
          // (default: `0`) Enforces indentation level for case clauses in switch statements
          SwitchCase: 1,
          // `true` (`false` by default) requires no indentation for ternary expressions which are nested in other ternary expressions.
          // flatTernaryExpressions: true,
          // `true` (`false` by default) requires indentation for values of ternary expressions.
          // offsetTernaryExpressions: false,
        },
      ],
    },
  },
  pluginJs.configs.recommended,
  eslintConfigPrettier,
];
