defmodule Blackjack do
  @moduledoc """
  Documentation for `Blackjack`.
  """

  def service_name(service_id) do
    {:via, Registry, {Blackjack.Registry, service_id}}
  end
end
