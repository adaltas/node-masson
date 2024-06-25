import globals from "globals";
import pluginJs from "@eslint/js";

export default [
  {
    languageOptions: { globals: { ...globals.node } },
    rules: {
      indent: [
        "error",
        2,
        {
          SwitchCase: 1,
          flatTernaryExpressions: true,
          offsetTernaryExpressions: false,
        },
      ],
    },
  },
  pluginJs.configs.recommended,
];
