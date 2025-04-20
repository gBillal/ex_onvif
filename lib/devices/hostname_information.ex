defmodule Onvif.Devices.HostnameInformation do
  @moduledoc """
  Scheme describing the hostname information of a device.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:name, :string)
    field(:from_dhcp, :boolean)
  end

  def parse(doc) do
    xmap(
      doc,
      name: ~x"./tt:Name/text()"s,
      from_dhcp: ~x"./tt:FromDHCP/text()"s
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(hostname_information, attrs) do
    hostname_information
    |> cast(attrs, [:name, :from_dhcp])
    |> validate_required([:from_dhcp])
  end
end
