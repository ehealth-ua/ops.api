defmodule DeactivateDeclarationConsumer.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Application.put_env(
      :kaffe,
      :consumer,
      Application.get_env(:deactivate_declaration_consumer, :kaffe_consumer)
    )

    children = [
      %{
        id: Kaffe.GroupMemberSupervisor,
        start: {Kaffe.GroupMemberSupervisor, :start_link, []},
        type: :supervisor
      }
    ]

    opts = [strategy: :one_for_one, name: DeactivateDeclarationConsumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
