#!/usr/bin/env node

import masson from 'masson';

masson(process.argv.slice(2)).catch((err) =>
  process.stderr.write(err.stack + "\n\n")
);
