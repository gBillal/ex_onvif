defmodule Onvif.Devices.NetworkProtocol do
  @moduledoc """
  A module describing a network protocol.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml
  import XmlBuilder

  @required [:name, :enabled, :port]

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:name, Ecto.Enum, values: [http: "HTTP", https: "HTTPS", rtsp: "RTSP"])
    field(:enabled, :boolean)
    field(:port, :integer)
  end

  def encode(%__MODULE__{} = network_protocol) do
    element(:"tds:NetworkProtocols", [
      element(
        :"tt:Name",
        Keyword.fetch!(Ecto.Enum.mappings(__MODULE__, :name), network_protocol.name)
      ),
      element(:"tt:Enabled", network_protocol.enabled),
      element(:"tt:Port", network_protocol.port)
    ])
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def parse(doc) do
    # Some Axis cameras return something like
    # ...
    # <tds:NetworkProtocols>
    #     <tt:Name>HTTP</tt:Name>
    #     <tt:Enabled>true</tt:Enabled>
    #     <tt:Port>80</tt:Port>
    #     <tt:Port>0</tt:Port>
    # </tds:NetworkProtocols>
    # ...
    # If parsed with: ~x"./tt:Port/text()"s this will return 800
    xmap(doc,
      name: ~x"./tt:Name/text()"s,
      enabled: ~x"./tt:Enabled/text()"s,
      port: ~x"./tt:Port/text()" |> transform_by(&List.to_string/1)
    )
  end
end
