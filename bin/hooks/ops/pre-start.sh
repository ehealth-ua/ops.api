#!/bin/sh
# `pwd` should be /opt/ops

if [ "${DB_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/ops command  Elixir.Core.ReleaseTasks migrate
fi;
