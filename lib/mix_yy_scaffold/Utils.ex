defmodule MixYyScaffold.Utils do
  @moduledoc """
  Utility functions relating to YY Scaffolding
  """

  def downcase(x) when is_binary(x), do: String.downcase(x)
  def downcase(nil), do: nil
  def downcase(_), do: raise("Not implemented")

  def parse_name(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.replace("-", "_")
    |> downcase
  end

  def parse_name(nil), do: nil
  def parse_name(_), do: raise("Not Implemented")
end
