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

## User interface

There's a user interface to edit records (slowly) in progress, too.
It's based on Backbone.js with Mustache templates to make sure we
don't make features in the API that are not reasonably universal. The
primary focus is on making a useful API; a good UI is just an extra
bonus.

### Compiled templates

To compile the user interface templates you need the 'hulk' tool from
[Hogan.js](http://twitter.github.com/hogan.js/).  To get it, install
[Node.js](http://nodejs.org/) and then run `npm install -g hogan`.

This is not needed if you just want to run the tool, only if you are
changing the templates.
