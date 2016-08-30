# PostgreSQL

PostgreSQL is a powerful, open source object-relational database system. 
It has more than 15 years of active development and a proven architecture that
has earned it a strong reputation for reliability, data integrity, and correctness.
It is fully ACID compliant, has full support for foreign keys, joins, views, triggers,
and stored procedures (in multiple languages).

Run this command on the host to enter psql:

```
docker exec -it -u postgres postgres_server psql
```


    module.exports = ->
      'configure':
        'masson/commons/postgres/server/configure'
      'check':
        'masson/commons/postgres/server/check'
      'install': [
        'masson/core/iptables'
        'masson/commons/postgres/server/install'
        'masson/commons/postgres/server/start'
        'masson/commons/postgres/server/check'
      ]
      'prepare':
        'masson/commons/postgres/server/prepare'
      "start":
        'masson/commons/postgres/server/start'
      "stop":
        'masson/commons/postgres/server/stop'
