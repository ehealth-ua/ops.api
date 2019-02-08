if [ "${KAFKA_MIGRATE}" == "true" ] && [ -f "./bin/${APP_NAME}" ]; then
  echo "[WARNING] Migrating kafka topics!"
  ./bin/deactivate_declaration_consumer command  Elixir.Core.KafkaTasks migrate
fi;
