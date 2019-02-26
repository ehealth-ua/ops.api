use Mix.Config

config :deactivate_declaration_consumer,
  kaffe_consumer: [
    endpoints: {:system, :string, "KAFKA_BROKERS"},
    topics: ["deactivate_declaration_events"],
    consumer_group: "ops",
    message_handler: DeactivateDeclarationConsumer.Kafka.DeactivateDeclarationEventConsumer
  ]
