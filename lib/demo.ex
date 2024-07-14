defmodule Demo do
  @moduledoc """
  Demo play
  """

  @spec run() :: any()

  def run do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    round_id = String.to_atom("round_#{:erlang.unique_integer()}")

    player_ids =
      Enum.map(1..5, fn i ->
        # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
        String.to_atom("player_#{i}")
      end)

    start_round(round_id, player_ids)
  end

  defp start_round(round_id, player_ids) do
    Demo.Autoplayer.Server.start_link(round_id, player_ids)

    players =
      Enum.map(player_ids, fn player_id ->
        Demo.Autoplayer.Server.player_spec(round_id, player_id)
      end)

    Blackjack.RoundsSupervisor.start_playing(round_id, players)
  end
end

defmodule Demo.Autoplayer do
  @moduledoc """
  Demo Autoplayer
  """

  alias Blackjack.Deck
  alias Blackjack.Hand
  alias Blackjack.Round

  defdelegate new, to: Hand

  @spec deal(hand :: Hand.t(), card :: Deck.card()) :: Hand.t()

  def deal(hand, card) do
    {_, hand} = Hand.deal(hand, card)
    hand
  end

  @spec next_move(hand :: Hand.t()) :: Round.move_type()

  def next_move(hand) do
    1
    |> :timer.seconds()
    |> :timer.sleep()

    if :rand.uniform(11) + 10 < hand.score do
      :stand
    else
      :hit
    end
  end
end

defmodule Demo.Autoplayer.Server do
  @moduledoc """
  Demo Autolplayer Server
  """

  alias Blackjack.Round
  alias Blackjack.RoundServer
  alias Demo.Autoplayer

  use GenServer

  require Logger

  @behaviour Blackjack.PlayerNotifier

  @spec start_link(round_id :: RoundServer.id(), player_ids :: [Round.player_id()]) ::
          GenServer.on_start()

  def start_link(round_id, player_ids) do
    GenServer.start_link(__MODULE__, {round_id, player_ids}, name: round_id)
  end

  @spec player_spec(round_id :: RoundServer.id(), player_id :: Round.player_id()) ::
          RoundServer.player()

  def player_spec(round_id, player_id) do
    %{
      id: player_id,
      callback_mod: __MODULE__,
      callback_arg: round_id
    }
  end

  @impl Blackjack.PlayerNotifier
  def deal_card(round_id, player_id, card) do
    GenServer.call(round_id, {:deal_card, player_id, card})
  end

  @impl Blackjack.PlayerNotifier
  def move(round_id, player_id) do
    GenServer.call(round_id, {:move, player_id})
  end

  @impl Blackjack.PlayerNotifier
  def busted(round_id, player_id) do
    GenServer.call(round_id, {:busted, player_id})
  end

  @impl Blackjack.PlayerNotifier
  def unauthorized_move(round_id, player_id) do
    GenServer.call(round_id, {:unauthorized_move, player_id})
  end

  @impl Blackjack.PlayerNotifier
  def winners(round_id, player_id, winners) do
    if Enum.member?(winners, player_id) do
      GenServer.call(round_id, {:won, player_id})
    end

    :ok
  end

  @impl GenServer
  def init({round_id, player_ids}) do
    players =
      player_ids
      |> Enum.map(fn player_id -> {player_id, Autoplayer.new()} end)
      |> Enum.into(%{})

    state = %{
      round_id: round_id,
      players: players
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:move, player_id}, from, state) do
    GenServer.reply(from, :ok)
    Logger.info("#{player_id}: thinking ...")
    next_move = Autoplayer.next_move(state.players[player_id])
    Logger.info("#{player_id}: #{next_move}")

    if next_move == :stand do
      Logger.info("")
    end

    Blackjack.RoundServer.move(state.round_id, player_id, next_move)
    {:noreply, state}
  end

  def handle_call({:deal_card, player_id, card}, _from, state) do
    Logger.info("#{player_id}: #{card.rank} of #{card.suit}")

    new_state =
      update_in(state.players[player_id], fn hand ->
        Autoplayer.deal(hand, card)
      end)

    {:reply, :ok, new_state}
  end

  def handle_call({:won, player_id}, _from, state) do
    Logger.info("#{player_id}: won")
    {:reply, :ok, state}
  end

  def handle_call({:busted, player_id}, _from, state) do
    Logger.info("#{player_id}: busted\n")
    {:reply, :ok, state}
  end
end
