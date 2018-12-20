#!/bin/sh
# `pwd` should be /opt/ops

if [ "${DB_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/ops command  Elixir.Core.ReleaseTasks migrate
fi;

APP_NAME="deactivate_declaration_consumer"
if [ "${KAFKA_MIGRATE}" == "true" ] && [ -f "./bin/${APP_NAME}" ]; then
  echo "[WARNING] Migrating kafka topics!"
  ./bin/$APP_NAME command  Elixir.Core.KafkaTasks migrate
fi;
