defmodule Blackjack.RoundServer do
  @moduledoc """
  Blackjack round server.
  """

  use GenServer

  alias Blackjack.PlayerNotifier
  alias Blackjack.Round
  alias Blackjack.RoundServer

  @rounds_supervisor Blackjack.RoundsSup

  @type id() :: any()
  @type callback_arg() :: [any()]
  @type player() :: %{
          id: Round.player_id(),
          callback_mod: module(),
          callback_arg: callback_arg()
        }

  @spec child_spec(init_arg :: any()) :: Supervisor.child_spec()

  def child_spec(_init_arg \\ []) do
    DynamicSupervisor.child_spec(name: @rounds_supervisor)
  end

  @spec start_round_supervisor(round_id :: RoundServer.id(), players :: [RoundServer.player()]) ::
          any()

  def start_round_supervisor(round_id, players) do
    round_server_spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [round_id, players]},
      type: :worker
    }

    children = [
      round_server_spec,
      PlayerNotifier.child_spec(round_id, players)
    ]

    opts = [strategy: :one_for_all]

    Supervisor.start_link(children, opts)
  end

  @spec start_playing(round_id :: id(), players :: [player()]) :: Supervisor.on_start_child()

  def start_playing(round_id, players) do
    child_spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_round_supervisor, [round_id, players]},
      type: :supervisor
    }

    DynamicSupervisor.start_child(@rounds_supervisor, child_spec)
  end

  @spec move(round_id :: id(), player_id :: Round.player_id(), move :: Round.move_type()) :: any()

  def move(round_id, player_id, move) do
    GenServer.call(round_id, {:move, player_id, move})
  end

  @type state() :: %{
          round_id: any(),
          round: Round.t()
        }

  @spec start_link(round_id :: id(), players :: [player()]) :: GenServer.on_start()

  def start_link(round_id, players) do
    player_ids = Enum.map(players, fn player -> player.id end)
    GenServer.start_link(__MODULE__, {round_id, player_ids}, name: round_id)
  end

  @impl GenServer
  def init({round_id, player_ids}) do
    {instructions, round} = Round.start(player_ids)
    state = %{round_id: round_id, round: round}
    new_state = handle_round_result({instructions, round}, state)

    {:ok, new_state}
  end

  @impl GenServer
  def handle_call({:move, player_id, move}, _from, state) do
    new_state =
      state.round
      |> Round.move(player_id, move)
      |> handle_round_result(state)

    {:reply, :ok, new_state}
  end

  @spec handle_round_result(round_result :: {[Round.instruction()], Round.t()}, state :: state()) ::
          state()

  def handle_round_result({instructions, round}, state) do
    Enum.reduce(instructions, %{state | round: round}, &handle_instruction/2)
  end

  @spec handle_instruction(instruction :: Round.instruction(), state :: state()) :: state()

  defp handle_instruction(instruction, state) do
    {:notify_player, _player_id, _player_instruction} = instruction
    state
  end
end
