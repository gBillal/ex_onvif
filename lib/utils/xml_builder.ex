defmodule ExOnvif.Utils.XmlBuilder do
  @moduledoc false

  def element(name), do: XmlBuilder.element(name)

  def element(builder \\ [], name, attrs \\ nil, value)

  def element(builder, _name, nil, nil), do: builder
  def element(builder, _name, nil, {_type, nil}), do: builder

  def element(builder, name, attrs, value) do
    [XmlBuilder.element(name, attrs, map(value)) | builder]
  end

  defp map(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp map({:duration, value}), do: "PT#{value}S"
  defp map(value), do: value
end
