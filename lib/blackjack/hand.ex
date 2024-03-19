defmodule Blackjack.Hand do
  @moduledoc """
  Blackjack Hand module.
  """

  alias __MODULE__
  alias Blackjack.Deck

  defstruct cards: [],
            score: nil

  @type t() :: %Hand{
          cards: [Deck.card()],
          score: nil | 4..21
        }

  @spec new() :: t()

  def new, do: %Hand{}

  @spec deal(hand :: t(), card :: Deck.card()) :: {:ok | :busted, t()}

  def deal(hand, card) do
    cards = [card | hand.cards]

    scores = [score(cards, :soft), score(cards, :hard)]

    {result, new_score} =
      case Enum.reject(scores, &busted?/1) do
        [] -> {:busted, nil}
        [best_score | _] -> {:ok, best_score}
      end

    {result, %Hand{hand | cards: cards, score: new_score}}
  end

  @spec busted?(score :: integer()) :: boolean()

  defp busted?(score), do: score > 21

  @type score_type() :: :soft | :hard

  @spec score(cards :: [Deck.card()], type :: score_type()) :: pos_integer()

  defp score(cards, type) do
    cards
    |> Stream.map(fn card -> value(card.rank, type) end)
    |> Enum.sum()
  end

  @spec value(rank :: Deck.rank(), type :: score_type()) :: 1..11

  defp value(num, _) when num in 2..10, do: num
  defp value(face, _) when face in [:jack, :queen, :king], do: 10
  defp value(:ace, :soft), do: 11
  defp value(:ace, :hard), do: 1
end
