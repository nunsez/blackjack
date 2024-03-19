defmodule Blackjack.Deck do
  @moduledoc """
  Blackjack Deck module.
  """

  @type suit() :: :spades | :hearts | :diamonds | :clubs
  @type rank() :: 2..4 | :jack | :queen | :king | :ace
  @type card() :: %{suit: suit(), rank: rank()}
  @type t() :: [card()]

  @cards (for suit <- [:spades, :hearts, :diamonds, :clubs],
              rank <- [2, 3, 4, 5, 6, 7, 8, 9, 10, :jack, :queen, :king, :ace] do
            %{suit: suit, rank: rank}
          end)

  @spec shuffled() :: t()

  def shuffled do
    Enum.shuffle(@cards)
  end

  @spec take(deck :: t()) :: {:ok, card(), t()} | {:error, :empty}

  def take([]) do
    {:error, :empty}
  end

  def take([card | rest]) do
    {:ok, card, rest}
  end
end
