#!/bin/bash

set -x

IMAGE_ID="microsoft/mssql-server-linux:2017-GA"
CONTAINER_NAME="mssql-query-runner"
SQL_FILE="test-queries.sql"
MSSQL_USERNAME="sa"
MSSQL_PASSWORD="testTEST123"
MSSQL_DATABASE="master"

docker kill $CONTAINER_NAME
docker rm $CONTAINER_NAME

docker run \
  -e ACCEPT_EULA=Y \
  -e MSSQL_SA_PASSWORD=$MSSQL_PASSWORD \
  -p 1433:1433 \
  --name=$CONTAINER_NAME \
  -d $IMAGE_ID

MSSQL_HOST=localhost
MSSQL_PORT=1433

echo "host: ${MSSQL_HOST}"
echo "port: ${MSSQL_PORT}"
echo "user: ${MSSQL_USERNAME}"
echo "pass: ${MSSQL_PASSWORD}"
echo "  db: ${MSSQL_DATABASE}"

coffee src/index.coffee \
  --query="SELECT 1" \
  --host=$MSSQL_HOST \
  --port=$MSSQL_PORT \
  --username=$MSSQL_USERNAME \
  --password=$MSSQL_PASSWORD \
  --database=$MSSQL_DATABASE \
  --connect-timeout=5000 \
  --total-timeout=30000

docker kill $CONTAINER_NAME
docker rm $CONTAINER_NAME

