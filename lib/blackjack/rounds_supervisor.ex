defmodule Blackjack.RoundsSupervisor do
  @moduledoc """
  Dynamic Supervisor handles rounds
  """

  alias Blackjack.PlayerNotifier
  alias Blackjack.RoundServer

  @spec child_spec(init_arg :: keyword()) :: Supervisor.child_spec()

  def child_spec(_init_arg \\ []) do
    DynamicSupervisor.child_spec(name: __MODULE__)
  end

  @spec start_playing(
          round_id :: RoundServer.id(),
          players :: [RoundServer.player()]
        ) :: Supervisor.on_start_child()

  def start_playing(round_id, players) do
    child_spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_round_supervisor, [round_id, players]},
      type: :supervisor
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec) |> dbg
  end

  @spec start_round_supervisor(round_id :: RoundServer.id(), players :: [RoundServer.player()]) ::
          any()

  def start_round_supervisor(round_id, players) do
    round_server_spec = %{
      id: RoundServer,
      start: {RoundServer, :start_link, [round_id, players]},
      type: :worker
    }

    children = [
      round_server_spec,
      PlayerNotifier.child_spec(round_id, players)
    ]

    opts = [strategy: :one_for_all]

    Supervisor.start_link(children, opts) |> dbg
  end
end
