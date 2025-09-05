defmodule ExOnvif.Utils.Parser do
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

  def get_namespace_prefix(xml_doc, namespace) do
    {:xmlNamespace, _, namespaces} = elem(xml_doc, 4)

    Enum.find_value(namespaces, fn {key, entity_namespace} ->
      if to_string(entity_namespace) == namespace, do: List.to_string(key)
    end)
  end
end
