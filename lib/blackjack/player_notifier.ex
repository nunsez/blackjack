defmodule Blackjack.PlayerNotifier do
  @moduledoc """
  Blackjack player notifier
  """

  use GenServer

  alias Blackjack.Round
  alias Blackjack.RoundServer

  @callback deal_card(RoundServer.id(), Round.player_id(), Blackjack.Deck.card()) :: any()
  @callback move(RoundServer.id(), Round.player_id()) :: any()
  @callback busted(RoundServer.id(), Round.player_id()) :: any()
  @callback winners(RoundServer.id(), Round.player_id(), [Round.player_id()]) :: any()
  @callback unauthorized_move(RoundServer.id(), Round.player_id()) :: any()

  @spec child_spec(round_id :: RoundServer.id(), players :: [RoundServer.player()]) ::
          Supervisor.child_spec()

  def child_spec(round_id, players) do
    children =
      Enum.map(players, fn player ->
        %{
          id: {__MODULE__, player.id},
          start: {__MODULE__, :start_link, [round_id, player]},
          type: :worker
        }
      end)

    supervisor_name = Blackjack.service_name({__MODULE__, round_id})
    opts = [strategy: :one_for_one, name: supervisor_name]
    %{
      id: {__MODULE__, round_id},
      start: {Supervisor, :start_link, [children, opts]},
      type: :supervisor
    }
  end

  @spec publish(
          round_id :: RoundServer.id(),
          player_id :: Round.player_id(),
          player_instruction :: Round.player_instruction()
        ) :: :ok

  def publish(round_id, player_id, player_instruction) do
    GenServer.cast(service_name(round_id, player_id), {:notify, player_instruction})
  end

  @spec start_link(round_id :: RoundServer.id(), player :: RoundServer.player()) ::
          GenServer.on_start()

  def start_link(round_id, player) do
    GenServer.start_link(__MODULE__, {round_id, player}, name: service_name(round_id, player.id))
  end

  @impl GenServer
  def init({round_id, player}) do
    state = %{round_id: round_id, player: player}
    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:notify, player_instruction}, state) do
    {fun, args} = decode_instruction(player_instruction)
    all_args = [state.player.callback_arg, state.player.id | args]
    apply(state.player.callback_mod, fun, all_args)

    {:noreply, state}
  end

  @spec decode_instruction(player_instruction :: Round.player_instruction()) :: {atom(), [any()]}

  defp decode_instruction({:deal_card, card}), do: {:deal_card, [card]}
  defp decode_instruction(:move), do: {:move, []}
  defp decode_instruction(:busted), do: {:busted, []}
  defp decode_instruction(:unauthorized_move), do: {:unauthorized_move, []}
  defp decode_instruction({:winners, player_ids}), do: {:winners, [player_ids]}

  defp service_name(round_id, player_id) do
    Blackjack.service_name({__MODULE__, round_id, player_id})
  end
end
