defmodule IRCd.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {IRCd.Server, []}
    ]

    opts = [strategy: :one_for_one, name: IRCd.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
