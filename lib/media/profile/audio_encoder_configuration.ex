defmodule Onvif.Media.Profile.AudioEncoderConfiguration do
  @moduledoc """
  Optional configuration of the Audio encoder.
  """

  use Ecto.Schema

  import Onvif.Utils.XmlBuilder
  import Ecto.Changeset
  import SweetXml

  alias Onvif.Media.Profile.MulticastConfiguration

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:reference_token, :string)
    field(:name, :string)
    field(:use_count, :integer)

    field(:encoding, Ecto.Enum,
      values: [
        g711: "G711",
        g726: "G726",
        aac: "AAC",
        pcmu: "PCMU",
        pcma: "PCMA",
        mp4a_latm: "MP4A-LATM"
      ]
    )

    field(:bitrate, :integer)
    field(:sample_rate, :integer)
    field(:session_timeout, :string)

    embeds_one(:multicast, MulticastConfiguration)
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      reference_token: ~x"./@token"s,
      name: ~x"./tt:Name/text()"s,
      use_count: ~x"./tt:UseCount/text()"i,
      encoding: ~x"./tt:Encoding/text()"s,
      bitrate: ~x"./tt:Bitrate/text()"i,
      sample_rate: ~x"./tt:SampleRate/text()"i,
      session_timeout: ~x"./tt:SessionTimeout/text()"s,
      multicast: ~x"./tt:Multicast"e |> transform_by(&MulticastConfiguration.parse/1)
    )
  end

  def encode(%__MODULE__{} = audio_encoder_config, name) do
    element(
      [],
      name,
      %{"token" => audio_encoder_config.reference_token},
      element("tt:Name", audio_encoder_config.name)
      |> element("tt:UseCount", audio_encoder_config.use_count)
      |> element(
        "tt:Encoding",
        Keyword.fetch!(
          Ecto.Enum.mappings(audio_encoder_config.__struct__, :encoding),
          audio_encoder_config.encoding
        )
      )
      |> element("tt:Bitrate", audio_encoder_config.bitrate)
      |> element("tt:SampleRate", audio_encoder_config.sample_rate)
      |> element("tt:Multicast", MulticastConfiguration.encode(audio_encoder_config.multicast))
      |> element("tt:SessionTimeout", audio_encoder_config.session_timeout)
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [
      :reference_token,
      :name,
      :use_count,
      :encoding,
      :bitrate,
      :sample_rate,
      :session_timeout
    ])
    |> cast_embed(:multicast)
  end
end
