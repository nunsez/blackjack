defmodule Blackjack.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Blackjack.Worker.start_link(arg)
      # {Blackjack.Worker, arg}
      {Registry, keys: :unique, name: Blackjack.Registry},
      {Blackjack.RoundsSupervisor, []}
      # Blackjack.RoundsSupervisor.child_spec()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Blackjack.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
