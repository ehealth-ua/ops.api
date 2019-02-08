defmodule DeactivateDeclarationConsumer.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    alias DeactivateDeclarationConsumer.Kafka.DeactivateDeclarationEventConsumer

    consumer_group_opts = [
      # setting for the ConsumerGroup
      heartbeat_interval: 1_000,
      # this setting will be forwarded to the GenConsumer
      commit_interval: 1_000
    ]

    gen_consumer_impl = DeactivateDeclarationEventConsumer
    consumer_group_name = "deactivate_declaration_events_group"
    topic_names = ["deactivate_declaration_events"]

    # List all child processes to be supervised
    children = [
      supervisor(KafkaEx.ConsumerGroup, [
        gen_consumer_impl,
        consumer_group_name,
        topic_names,
        consumer_group_opts
      ])
    ]

    opts = [strategy: :one_for_one, name: DeactivateDeclarationConsumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
