P = require 'bluebird'
mssql = require 'mssql'
program = require 'commander'
durations = require 'durations'

config = require './config'

getConnection = (cfg, connectTimeout) ->
  client = P.resolve(mssql.connect cfg)
  .timeout connectTimeout
  .then (client) -> client
  .catch (error) ->
    mssql.close()
    throw error

# Wait for MSSQL to become available
waitForMSSQL = (partialConfig) ->
  config.validate partialConfig
  .then (cfg) ->
    new P (resolve) ->
      {
        username, password, host, port, database,
        connectTimeout, totalTimeout, query,
      } = cfg

      clientConfig =
        user : username
        password : password
        server : host
        port : port
        database : database
        connectionTimeout : connectTimeout

      watch = durations.stopwatch().start()
      connectWatch = durations.stopwatch()

      attempts = 0

      # Recursive connection test function
      testConnection = () ->
        attempts += 1
        connectWatch.reset().start()

        # Establish a client connection
        getConnection clientConfig, connectTimeout

        # Run the test query with the connected client
        .then (client) ->
          connectWatch.stop()

          # If a query was supplied, it must succeed before reporting success
          if query?
            console.log "Connected. Running test query: '#{query}'"
            client.request().query query, (error, result) ->
              console.log "Query done."
              client.close()
              if (error)
                console.log "[#{error}] Attempt #{attempts} query failure. Time elapsed: #{watch}" 
                if watch.duration().millis() > totalTimeout
                  console.log "MSSQL test query failed." 
                  resolve 1
                else
                  totalRemaining = Math.min connectTimeout, Math.max(0, totalTimeout - watch.duration().millis())
                  connectDelay = Math.min totalRemaining, Math.max(0, connectTimeout - connectWatch.duration().millis())
                  setTimeout testConnection, connectDelay
              else
                watch.stop()
                console.log "Query succeeded after #{attempts} attempt(s) over #{watch}"
                resolve 0
          # If a query was not supplied, report success
          else
            watch.stop()
            console.log "Connected after #{attempts} attempt(s) over #{watch}"
            client.close()
            resolve 0

        # Handle connection failure
        .catch (error) ->
          connectWatch.stop()
          console.log "[#{error}] Attempt #{attempts} timed out. Time elapsed: #{watch}" 
          if watch.duration().millis() > totalTimeout
            console.log "Could not connect to MSSQL." 
            resolve 1
          else
            totalRemaining = Math.min connectTimeout, Math.max(0, totalTimeout - watch.duration().millis())
            connectDelay = Math.min totalRemaining, Math.max(0, connectTimeout - connectWatch.duration().millis())
            setTimeout testConnection, connectDelay

      # First attempt
      testConnection()

# Script was run directly
runScript = () ->
  program
    .option '-D, --database <database>', 'MSSQL database name (default is master)'
    .option '-h, --host <host>', 'MSSQL hostname (default is localhost)'
    .option '-p, --port <port>', 'MSSQL port (default is 1433)', parseInt
    .option '-P, --password <password>', 'MSSQL user password (default is empty)'
    .option '-Q, --query <query_string>', 'Custom query to confirm database state'
    .option '-t, --connect-timeout <connect-timeout>', 'Individual connection attempt timeout (default is 1000)', parseInt
    .option '-T, --total-timeout <total-timeout>', 'Total timeout across all connect attempts (dfault is 15000)', parseInt
    .option '-u, --username <username>', 'MSSAQL user name (default is sa)'
    .parse(process.argv)

  partialConfig =
    host: program.host
    port: program.port
    username: program.username
    password: program.password
    database: program.database
    connectTimeout: program.connectTimeout
    totalTimeout: program.totalTimeout
    query: program.query

  waitForMSSQL(partialConfig)
  .then (code) ->
    process.exit code

# Module
module.exports =
  await: waitForMSSQL
  run: runScript

# If run directly
if require.main == module
  runScript()

