defmodule Blackjack.Round do
  @moduledoc """
  Blackjack Round module.
  """

  alias __MODULE__
  alias Blackjack.Deck
  alias Blackjack.Hand

  defstruct deck: nil,
            current_hand: nil,
            current_player_id: nil,
            all_players: [],
            remaining_players: [],
            successful_hands: [],
            instructions: []

  @type t() :: %Round{
          deck: Deck.t(),
          current_hand: Hand.t() | nil,
          current_player_id: player_id(),
          all_players: [player_id()],
          remaining_players: [player_id()],
          successful_hands: [%{player_id: player_id(), hand: Hand.t()}],
          instructions: [instruction()]
        }

  @type player_id() :: any()

  @type player_instruction() ::
          {:deal_card, Deck.card()}
          | :move
          | :busted
          | {:winners, [player_id()]}
          | :unauthorized_move

  @type instruction :: {:notify_player, player_id(), player_instruction()}

  @type move_type() :: :stand | :hit

  @spec start(playerd_ids :: [player_id()]) :: {[instruction()], t()}

  def start(playerd_ids) when is_list(playerd_ids) do
    start(playerd_ids, Deck.shuffled())
  end

  @spec move(round :: t(), player_id :: player_id(), move_type :: move_type()) ::
          {[instruction()], t()}

  def move(%Round{current_player_id: player_id} = round, player_id, move_type) do
    %Round{round | instructions: []}
    |> handle_move(move_type)
    |> instructions_and_state()
  end

  def move(%Round{} = round, player_id, _move_type) do
    %Round{round | instructions: []}
    |> notify_player(player_id, :unauthorized_move)
    |> instructions_and_state()
  end

  @spec start(player_ids :: [player_id()], deck :: Deck.t()) :: {[instruction()], t()}

  def start(player_ids, deck) do
    round = %Round{
      deck: deck,
      current_hand: nil,
      current_player_id: nil,
      all_players: player_ids,
      remaining_players: player_ids,
      successful_hands: [],
      instructions: []
    }

    round
    |> start_new_hand()
    |> instructions_and_state()
  end

  @spec start_new_hand(round :: t()) :: t()

  defp start_new_hand(%Round{remaining_players: []} = round) do
    winners = winners(round)

    Enum.reduce(
      round.all_players,
      %Round{round | current_hand: nil, current_player_id: nil},
      fn player_id, round -> notify_player(round, player_id, {:winners, winners}) end
    )
  end

  defp start_new_hand(%Round{} = round) do
    [current_player_id | remaining_players] = round.remaining_players

    round = %Round{
      round
      | current_hand: Hand.new(),
        current_player_id: current_player_id,
        remaining_players: remaining_players
    }

    {:ok, round} = deal(round)
    {:ok, round} = deal(round)
    # credo:disable-for-previous-line Credo.Check.Refactor.VariableRebinding

    round
  end

  @spec handle_move(round :: t(), move_type :: move_type()) :: t()

  defp handle_move(%Round{} = round, :stand) do
    round
    |> hand_successed()
    |> start_new_hand()
  end

  defp handle_move(%Round{} = round, :hit) do
    case deal(round) do
      {:ok, round} ->
        round

      {:busted, round} ->
        round
        |> notify_player(round.current_player_id, :busted)
        |> start_new_hand()
    end
  end

  @spec deal(round :: t()) :: {:ok | :busted, t()}

  defp deal(%Round{} = round) do
    {:ok, card, deck} =
      case Deck.take(round.deck) do
        {:error, :empty} -> Deck.take(Deck.shuffled())
        {:ok, _, _} = result -> result
      end

    {hand_status, hand} = Hand.deal(round.current_hand, card)

    round =
      notify_player(
        %Round{round | deck: deck, current_hand: hand},
        round.current_player_id,
        {:deal_card, card}
      )

    {hand_status, round}
  end

  @spec hand_successed(round :: t()) :: t()

  defp hand_successed(%Round{} = round) do
    hand_data = %{player_id: round.current_player_id, hand: round.current_hand}
    %Round{round | successful_hands: [hand_data | round.successful_hands]}
  end

  @spec winners(round :: t()) :: [player_id()]

  defp winners(%Round{successful_hands: []}) do
    []
  end

  defp winners(%Round{} = round) do
    max_score =
      Enum.max_by(round.successful_hands, fn hand_data -> hand_data.hand.score end).hand_data.score

    round.successful_hands
    |> Stream.filter(fn hand_data -> hand_data.hand.score == max_score end)
    |> Stream.map(fn hand_data -> hand_data.player_id end)
    |> Enum.reverse()
  end

  @spec notify_player(round :: t(), player_id :: player_id(), data :: player_instruction()) :: t()

  defp notify_player(%Round{} = round, player_id, data) do
    instruction = {:notify_player, player_id, data}
    %Round{round | instructions: [instruction | round.instructions]}
  end

  @spec instructions_and_state(round :: t()) :: {[instruction()], t()}

  def instructions_and_state(%Round{} = round) do
    round
    |> tell_current_player_to_move()
    |> take_instructions()
  end

  @spec tell_current_player_to_move(round :: t()) :: t()

  def tell_current_player_to_move(%Round{current_player_id: nil} = round) do
    round
  end

  def tell_current_player_to_move(%Round{} = round) do
    notify_player(round, round.current_player_id, :move)
  end

  @spec take_instructions(round :: t()) :: {[instruction()], t()}

  def take_instructions(%Round{} = round) do
    instructions = Enum.reverse(round.instructions)
    new_round = %Round{round | instructions: []}
    {instructions, new_round}
  end
end
