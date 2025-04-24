defmodule Onvif.Utils.Parser do
  @moduledoc false

  def parse_map_reduce(entries, module) do
    entries
    |> Enum.map(&module.parse/1)
    |> Enum.reduce_while([], fn raw_config, acc ->
      case module.to_struct(raw_config) do
        {:ok, config} -> {:cont, [config | acc]}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:error, _reason} = err -> err
      configs -> {:ok, Enum.reverse(configs)}
    end
  end
end
