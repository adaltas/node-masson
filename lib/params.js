
import load from "masson/utils/load";

export default {
  name: "masson",
  description: "Cluster deployment and management.",
  load: load,
  options: {
    config: {
      shortcut: "c",
      type: "array",
      description: "One or multiple configuration files.",
    },
    stacktrace: {
      shortcut: "s",
      type: "boolean",
      description: "Print readable stacktrace.",
    },
  },
  commands: {
    grpc: {
      description: "Remote access through grpc.",
      commands: {
        start: {
          description: "Start the GRPC server.",
          handler: "masson/commands/grpc/start",
        },
        status: {
          description: "Print the server status.",
          handler: "masson/commands/grpc/status",
        },
        stop: {
          description: "Stop the GRPC server",
          handler: "masson/commands/grpc/stop",
        },
      },
    },
    pki: {
      description: "Certificate Management for development usage.",
      options: {
        dir: {
          shortcut: "d",
          type: "string",
          description: "Output directory",
          required: true,
        },
      },
      commands: {
        ca: {
          description: "Generate the Certificate Authority.",
          handler: "masson/commands/pki/ca",
        },
        "cacert-view": {
          description: "Display detailed information of a certificate.",
          handler: "masson/commands/pki/cacert-view",
        },
        check: {
          description: "Validate the certificate against the authority.",
          main: {
            name: "fqdn",
            required: true,
            description: "The FQDN associated with the certificate.",
          },
          handler: "masson/commands/pki/check",
        },
        cert: {
          description:
            "Generate the private and public key pair for a given FQDN.",
          main: {
            name: "fqdn",
            required: true,
            description: "The FQDN associated with the certificate",
          },
          handler: "masson/commands/pki/cert",
        },
        "cert-view": {
          description: "Display detailed information of a certificate.",
          main: {
            name: "fqdn",
            description: "The FQDN associated with the certificate.",
          },
          handler: "masson/commands/pki/cert-view",
        },
      },
    },
    secrets: {
      description: "Interact with the secure secret file store.",
      options: {
        store: {
          default: ".secrets",
          description: "File storing the secrets",
          shortcut: "s",
          type: "string",
        },
        envpw: {
          default: "MASSON_SECRET_PW",
          description: "Environment variable storing the password.",
          shortcut: "e",
          type: "string",
        },
      },
      commands: {
        init: {
          description: "Initialize the secret store",
          handler: "masson/commands/secrets/init",
        },
        unset: {
          description: "Delete a secret from the store.",
          handler: "masson/commands/secrets/unset",
          main: {
            name: "properties",
            required: true,
            description: "One or multiple property name.",
          },
        },
        get: {
          description: "Get a secret",
          handler: "masson/commands/secrets/get",
          main: {
            name: "properties",
            required: true,
            description: "One or multiple property name.",
          },
          options: {
            format: {
              description:
                "Output format, only apply if propery is not a leaf.",
              default: "yaml",
              enum: ["json", "prettyjson", "yaml"],
              shortcut: "f",
              type: "string",
            },
          },
        },
        set: {
          description: "Set a secret",
          handler: "masson/commands/secrets/set",
          main: {
            name: "property",
            description: "Property name",
          },
          options: {
            overwrite: {
              type: "boolean",
              shortcut: "o",
              default: false,
              description: "Overwrite an existing property.",
            },
          },
        },
        show: {
          description: "Display all the secrets",
          handler: "masson/commands/secrets/show",
          options: {
            format: {
              description:
                "Output format, only apply if propery is not a leaf.",
              default: "yaml",
              enum: ["json", "prettyjson", "yaml"],
              shortcut: "f",
              type: "string",
            },
          },
        },
      },
    },
    exec: {
      description: "Distribute a shell command",
      handler: "masson/commands/exec",
      main: {
        name: "subcommand",
        description: "The subcommand to execute.",
      },
      options: {
        nodes: {
          shortcut: "n",
          type: "array",
          description: "Limit to a list of server FQDNs.",
        },
        tags: {
          shortcut: "t",
          type: "array",
          description: "Limit to servers that honor a list of tags.",
        },
      },
    },
    configure: {
      description: "Export servers' configuration in a file.",
      handler: "masson/commands/configure",
      options: {
        output: {
          shortcut: "o",
          type: "string",
          description: "output directory.",
        },
        format: {
          shortcut: "f",
          type: "string",
          description: "Format of the output files: [json, cson, js, coffee].",
          one_of: ["json", "cson", "js", "coffee"],
        },
        nodes: {
          shortcut: "n",
          type: "boolean",
          description: "Print configuration of nodes.",
        },
        cluster: {
          shortcut: "c",
          type: "string",
          description: "Print configuration of clusters.",
        },
        clusters: {
          type: "boolean",
          description: "Print list of cluster names.",
        },
        service: {
          shortcut: "s",
          type: "string",
          description:
            "Print configuration of a services (format cluster:service).",
        },
        service_names: {
          type: "boolean",
          description: "Print list of service names",
        },
      },
    },
    graph: {
      description: "Print the execution plan",
      handler: "masson/commands/graph",
      options: {
        output: {
          shortcut: "o",
          type: "string",
          description: "output directory",
        },
        format: {
          shortcut: "f",
          type: "string",
          description: "Format of the output files: [json, cson, js, coffee]",
          one_of: ["json", "cson", "js", "coffee"],
        },
        nodes: {
          shortcut: "n",
          type: "boolean",
          description: "Print nodes information",
        },
      },
    },
    server: {
      description: "Print the execution plan",
      commands: {
        start: {
          description: "Start the server",
          options: {
            directory: {
              description: "Directory to serve",
              default: "../ryba-repos/public",
              shortcut: "d",
            },
            pidfile: {
              description: "File storing the process ID",
              default: "./conf/server.pid",
            },
            port: {
              description: "Port used by the server",
              default: 5680,
              shortcut: "p",
              type: "integer",
            },
          },
          handler: "masson/commands/server/start",
        },
        stop: {
          description: "Stop the server",
          options: {
            port: {
              description: "Port used by the server",
              default: 5680,
              shortcut: "p",
              type: "integer",
            },
            directory: {
              description: "Directory to serve",
              default: "../ryba-repos/public",
              shortcut: "d",
            },
            pidfile: {
              description: "File storing the process ID",
              default: "./conf/server.pid",
            },
          },
          handler: "masson/commands/server/stop",
        },
        status: {
          description: "Is the server routening?",
          options: {
            pidfile: {
              description: "File storing the process ID",
              default: "./conf/server.pid",
            },
          },
          handler: "masson/commands/server/status",
        },
      },
    },
    init: {
      description: "Create a project with a default layout and configuration",
      handler: "masson/commands/init",
      options: {
        debug: {
          shortcut: "d",
          type: "boolean",
          description: "Print debug output",
        },
        description: {
          shortcut: "i",
          type: "string",
          description: "Project description",
        },
        latest: {
          shortcut: "l",
          type: "boolean",
          description:
            "Enable a development environment such as using latest git for package dependencies.",
        },
        name: {
          shortcut: "n",
          type: "string",
          description: "Project name",
          required: true,
        },
        path: {
          shortcut: "p",
          type: "string",
          description:
            "Path to the project directory, default to the current directory.",
        },
      },
    },
  },
};
