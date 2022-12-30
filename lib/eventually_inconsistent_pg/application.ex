defmodule EventuallyInconsistentPg.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EventuallyInconsistentPg.Core
    ]

    opts = [strategy: :one_for_one, name: EventuallyInconsistentPg.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
