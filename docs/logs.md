
# Logs

Masson provides robust logging capabilities to help you monitor and debug your automation tasks. Logs are crucial for understanding the execution flow, diagnosing issues, and auditing operations.

## Overview

Logs in Project Name are stored in a structured manner, with one log file per node. This approach helps in isolating the logs of each node, making it easier to troubleshoot specific nodes without sifting through a consolidated log file.

## Log Directory Structure

Logs are stored in a dedicated directory within your project workspace. The default log directory structure is as follows:

```text
./logs/
    ├── node-1.md
    ├── node-2.md
    └── node-3.md
```

Each log file is named after the node it corresponds to (e.g., "node-1.md" for the node named "node-1").

The Markdown format is used to generate a human readable output.
