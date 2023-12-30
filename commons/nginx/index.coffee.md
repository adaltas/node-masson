
# NGINX Web Server

NGINX is a free, open-source, high-performance HTTP server and reverse proxy, as
well as an IMAP/POP3 proxy server. NGINX is known for its high performance,
stability, rich feature set, simple configuration, and low resource consumption.


    export default
      deps:
        iptables: module: 'masson/core/iptables', local: true
      configure:
        'masson/commons/nginx/configure'
      commands:
        'install': [
          'masson/commons/nginx/install'
          'masson/commons/nginx/start'
        ]
        'start':
          'masson/commons/nginx/start'
        'status':
          'masson/commons/nginx/status'
        'stop':
          'masson/commons/nginx/stop'
