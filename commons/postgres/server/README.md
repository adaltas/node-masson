
# PostgreSQL Server

PostgreSQL is a powerful, open source object-relational database system. 
It has more than 15 years of active development and a proven architecture that
has earned it a strong reputation for reliability, data integrity, and correctness.
It is fully ACID compliant, has full support for foreign keys, joins, views, triggers,
and stored procedures (in multiple languages).

Run this command on the host to enter psql:

```
docker exec -it -u postgres postgres_server psql
```

## IPTables

| Service    | Port | Proto | Parameter |
|------------|------|-------|-----------|
| PostgreSQL | 5432 | tcp   | -         |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).
