
Wait for MSSQL
===========

Waits for a MSSQL connection to become available, optionally running
a custom query to determine if the connection is valid.

Installation
============

```bash
npm install --save wait-for-mssql
```

Usage
=====

Run as a module within another script:

```coffeescript
waitForMSSQL = require 'wait-for-mssql'
config =
  username: user
  password: pass
  query: 'SELECT 1'

waitForMSSQL.wait(config)
```
      

Or run stand-alone

```bash
wait-for-mssql --username=user --password=pass
```

Building
============

cake build
