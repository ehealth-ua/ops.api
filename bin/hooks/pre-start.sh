#!/bin/sh
# `pwd` should be /opt/ops
APP_NAME="ops"

if [ "${DB_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/$APP_NAME command  Elixir.Core.ReleaseTasks migrate
fi;
