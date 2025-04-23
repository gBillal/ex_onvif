defmodule Onvif.Devices.NetworkInterface.PrefixedIPAddress do
  @moduledoc """
  Schema describing a prefixed IPv4/IPv6 address.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:address, :string)
    field(:prefix_length, :integer)
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      address: ~x"./tt:Address/text()"s,
      prefix_length: ~x"./tt:PrefixLength/text()"s
    )
  end

  def changeset(from_dhcp, attrs) do
    cast(from_dhcp, attrs, [:address, :prefix_length])
  end
end
