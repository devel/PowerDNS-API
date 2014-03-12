# PowerDNS::API

HTTP/JSON API for the [PowerDNS](http://www.powerdns.com/)
authoritative DNS server.

This makes it easy to program DNS changes without every system having
a database connection or full access to the DNS database.

There are basic [installation
instructions](https://github.com/devel/PowerDNS-API/wiki/Installation)
on the wiki.

## Database setup

The system needs an 'accounts' table and a 'cas' column in the domains
table.  The docs/schema.sql file has the SQL to be run to set this up.

For the 'CAS' API system to work properly, the system expects the
transaction isolation level of MySQL to be 'REPEATABLE READ' (this is
the default).



## New Command Implementation -  Delete domain

 example curl -X DELETE -u username:password http://apidomain/api/domain/:id