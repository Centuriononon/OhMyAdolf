#!/bin/bash

set -e

echo "-- Waiting for database..."
while ! curl -s -I ${NEO4J_HTTP_URL} | grep -q "200 OK"; do
  sleep 1
done

echo "-- Starting service..."
$@