defmodule Onvif.Devices.NetworkInterface.ConnectionSetting do
  @moduledoc """
  Schema describing a connection setting.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:auto_negotiation, :boolean)
    field(:speed, :integer)
    field(:duplex, Ecto.Enum, values: [half: "Half", full: "Full"])
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      auto_negotiation: ~x"./tt:AutoNegotiation/text()"s,
      speed: ~x"./tt:Speed/text()"s,
      duplex: ~x"./tt:Duplex/text()"s
    )
  end

  def changeset(from_dhcp, attrs) do
    cast(from_dhcp, attrs, [:auto_negotiation, :speed, :duplex])
  end
end
