defmodule ExOnvif.Fault do
  @moduledoc """
  Parses ONVIF SOAP fault responses into structured Fault structs.
  """

  import SweetXml

  @soap_env "http://www.w3.org/2003/05/soap-envelope"

  defmodule Code do
    @type t :: %__MODULE__{value: String.t(), subcode: ExOnvif.Fault.SubCode.t() | nil}

    @enforce_keys [:value]
    defstruct [:value, subcode: nil]
  end

  defmodule SubCode do
    @type t :: %__MODULE__{value: String.t(), subcode: t() | nil}

    @enforce_keys [:value]
    defstruct [:value, subcode: nil]
  end

  @type t :: %__MODULE__{code: Code.t(), reason: String.t(), detail: map() | nil}

  @enforce_keys [:code, :reason]
  defstruct [:code, :reason, detail: nil]

  @doc """
  Parses a SOAP fault XML body.
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, :parse_error}
  def parse(xml) when is_binary(xml) do
    doc = SweetXml.parse(xml, namespace_conformant: true)
    fault_node = xpath(doc, ~x"//env:Fault"eo |> add_namespace("env", @soap_env))

    case fault_node do
      nil ->
        {:error, :parse_error}

      node ->
        %{code_value: code_value, reason: reason} =
          xmap(node,
            code_value: ~x"./env:Code/env:Value/text()"s |> add_namespace("env", @soap_env),
            reason: ~x"./env:Reason/env:Text/text()"s |> add_namespace("env", @soap_env)
          )

        if code_value == "" do
          {:error, :parse_error}
        else
          subcode_node =
            xpath(node, ~x"./env:Code/env:Subcode"eo |> add_namespace("env", @soap_env))

          detail_node = xpath(node, ~x"./env:Detail"eo |> add_namespace("env", @soap_env))

          {:ok,
           %__MODULE__{
             code: %Code{value: code_value, subcode: build_subcode(subcode_node)},
             reason: reason,
             detail: node_children_to_map(detail_node)
           }}
        end
    end
  rescue
    _ -> {:error, :parse_error}
  catch
    :exit, _ -> {:error, :parse_error}
  end

  defp build_subcode(nil), do: nil

  defp build_subcode(subcode_node) do
    value = xpath(subcode_node, ~x"./env:Value/text()"s |> add_namespace("env", @soap_env))
    nested = xpath(subcode_node, ~x"./env:Subcode"eo |> add_namespace("env", @soap_env))
    %SubCode{value: value, subcode: build_subcode(nested)}
  end

  # Returns nil when there's no detail node, or a map of the detail's children.
  defp node_children_to_map(nil), do: nil

  defp node_children_to_map(node) do
    node
    |> elem(8)
    |> Enum.filter(&(elem(&1, 0) == :xmlElement))
    |> Enum.reduce(%{}, fn child, acc ->
      key = child |> elem(1) |> to_string()
      Map.put(acc, key, node_to_value(child))
    end)
  end

  # For leaf elements returns the trimmed text content; for parent elements
  # returns a map of their children (merging repeated tags into lists).
  defp node_to_value(node) do
    content = elem(node, 8)
    children = Enum.filter(content, &(elem(&1, 0) == :xmlElement))

    if children == [] do
      content
      |> Enum.filter(&(elem(&1, 0) == :xmlText))
      |> Enum.map_join("", &(elem(&1, 4) |> List.to_string()))
      |> String.trim()
    else
      Enum.reduce(children, %{}, fn child, acc ->
        key = child |> elem(1) |> to_string()
        value = node_to_value(child)

        Map.update(acc, key, value, fn existing ->
          List.wrap(existing) ++ [value]
        end)
      end)
    end
  end
end
