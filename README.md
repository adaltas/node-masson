
# Masson automation tool

## Introduction

Masson is an open-source automation tool designed to simplify the management and configuration of IT infrastructure. The project uses simple, human-readable YAML syntax to define automation tasks, making it easy to automate repetitive tasks, deploy applications, and manage complex infrastructure efficiently.

## Features

- Agentless Architecture: No need to install agents on remote nodes.
- YAML Syntax: Simple, readable YAML syntax for writing automation scripts.
- Modular Design: Extend functionality with custom modules and plugins.
- Parallel Execution: Perform tasks concurrently across multiple nodes.
- Idempotent Operations: Ensure that tasks achieve the desired state without unintended side effects.
- Secure: Utilizes SSH for secure communication with remote nodes.

## Getting Started

Follow these instructions to get a Masson project up and running on your local machine for development and testing purposes.

Install Node.js version 22 or above, for example with [n-install](https://github.com/mklement0/n-install).

```bash
curl -L https://bit.ly/n-install | bash
node -v
```

Initialise a new Masson project.

```bash
npx masson init <project_directory>
```

## Usage

Here is a simple example to get you started. This example pings a group of hosts to check their availability.

Define the nodes to manage in `./conf/nodes.yml`.

```yaml
worker-1:
  metadata:
    header: Worker node 1
  config:
    ip: 10.10.10.11
    fqdn: worker-1.localhost
    username: arcep
worker-2:
  metadata:
    header: Worker node 2
  config:
    ip: 10.10.10.12
    fqdn: worker-2.localhost
    username: arcep
worker-3:
  metadata:
    header: Worker node 3
  config:
    ip: 10.10.10.13
    fqdn: worker-3.localhost
    username: arcep
```

Create a group of actions in `./conf/actions.yaml

```yaml
check:
  metadata:
    header: Check
    commands: [check]
    nodes: '*'
  actions:
    ping:
      module: @nikitajs/core/execute
      metadata:
        header: Ping
      config:
        command: ping -c 1 {{node.fqdn}}
```

Run the check command.

```yaml
npx masson -c conf check
```

Filter actions and nodes.

```yaml
npx masson -c conf check -a 'check/*' -n 'worker-*'
```

## Documentation

Comprehensive documentation is available to help you get the most out of Project Name. It includes:

- Getting Started Guide  
  Step-by-step instructions to set up and configure Project Name.

  - [Installation](./docs/installation.md)
  - [CLI Usage](./docs/cli.md)

- User Guide
  Detailed information on how to use the tool, including examples and best practices.

  - [Actions](./docs/actions.md)
  - [Configuration discovery](./docs/config-discovery.md)
  - [Configuration structure](./docs/config-structure.md)
  - [Logs](./docs/logs.md)

- Configuration Reference  
  In-depth descriptions of how to declare the configuration.

  - [Action definition](./docs/definition-actions.md)
  - [Masson definition](./docs/definition-masson.md)

## Contributing

We welcome contributions from the community! To contribute:

- Fork the repository.
- Create a new branch (git checkout -b feature-branch).
- Commit your changes (git commit -m 'Add some feature').
- Push to the branch (git push origin feature-branch).
- Create a new Pull Request.

Please read our Contributing Guidelines (todo) for more details.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
