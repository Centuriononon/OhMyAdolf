#!/bin/bash

set -e

echo "-- Waiting for database..."
while ! curl -s -I http://localhost:7475 | grep -q "200 OK"; do
  echo "-- Pinging the database"
  sleep 1
done

echo "-- Starting service..."
$@