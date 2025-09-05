defmodule ExOnvif.Media2.Profile do
  @moduledoc """
  A media profile
  """

  use Ecto.Schema

  import Ecto.Changeset
  import ExOnvif.Utils.Parser, only: [get_namespace_prefix: 2]
  import SweetXml

  alias ExOnvif.Media.Profile.AudioSourceConfiguration
  alias ExOnvif.Media.Profile.AudioEncoderConfiguration
  alias ExOnvif.Media.Profile.MetadataConfiguration
  alias ExOnvif.Media.Profile.PtzConfiguration
  alias ExOnvif.Media.Profile.VideoAnalyticsConfiguration
  alias ExOnvif.Media.Profile.VideoSourceConfiguration
  alias ExOnvif.Media2.Profile.VideoEncoder

  @profile_permitted [:reference_token, :fixed, :name]
  @media2_namespace "http://www.onvif.org/ver20/media/wsdl"

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field :reference_token, :string
    field :fixed, :boolean
    field :name, :string

    embeds_one :audio_encoder_configuration, AudioEncoderConfiguration
    embeds_one :audio_source_configuration, AudioSourceConfiguration
    embeds_one :metadata_configuration, MetadataConfiguration
    embeds_one :ptz_configuration, PtzConfiguration
    embeds_one :video_analytics_configuration, VideoAnalyticsConfiguration
    embeds_one :video_encoder_configuration, VideoEncoder
    embeds_one :video_source_configuration, VideoSourceConfiguration

    embeds_one :extension, Extension, primary_key: false do
      @derive Jason.Encoder
      embeds_one :audio_decoder_configuration, AudioDecoderConfiguration, primary_key: false do
        @derive Jason.Encoder
        field :reference_token, :string
        field :name, :string
        field :use_count, :integer
      end

      embeds_one :audio_output_configuration, AudioOutputConfiguration do
        @derive Jason.Encoder
        field :reference_token, :string
        field :name, :string
        field :use_count, :integer
        field :output_token, :string
        field :send_primacy, :string
        field :output_level, :integer
      end
    end
  end

  def parse(nil), do: nil

  def parse(doc) do
    ns = get_namespace_prefix(doc, @media2_namespace)

    xmap(
      doc,
      reference_token: ~x"./@token"s,
      name: ~x"./#{ns}:Name/text()"s,
      fixed: ~x"./@fixed"s,
      audio_encoder_configuration:
        ~x"./#{ns}:Configurations/#{ns}:AudioEncoder"e
        |> transform_by(&AudioEncoderConfiguration.parse/1),
      audio_source_configuration:
        ~x"./#{ns}:Configurations/#{ns}:AudioSource"e
        |> transform_by(&AudioSourceConfiguration.parse/1),
      metadata_configuration:
        ~x"./#{ns}:Configurations/#{ns}:Metadata"e |> transform_by(&MetadataConfiguration.parse/1),
      video_encoder_configuration:
        ~x"./#{ns}:Configurations/#{ns}:VideoEncoder"e |> transform_by(&VideoEncoder.parse/1),
      video_source_configuration:
        ~x"./#{ns}:Configurations/#{ns}:VideoSource"e
        |> transform_by(&VideoSourceConfiguration.parse/1),
      video_analytics_configuration:
        ~x"./#{ns}:Configurations/#{ns}:Analytics"e
        |> transform_by(&VideoAnalyticsConfiguration.parse/1)
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, @profile_permitted)
    |> cast_embed(:audio_encoder_configuration)
    |> cast_embed(:audio_source_configuration)
    |> cast_embed(:extension, with: &extension_changeset/2)
    |> cast_embed(:metadata_configuration)
    |> cast_embed(:ptz_configuration)
    |> cast_embed(:video_analytics_configuration)
    |> cast_embed(:video_encoder_configuration)
    |> cast_embed(:video_source_configuration)
  end

  defp extension_changeset(module, attrs) do
    module
    |> cast(attrs, [])
    |> cast_embed(:audio_decoder_configuration, with: &audio_decoder_configuration_changeset/2)
    |> cast_embed(:audio_output_configuration, with: &audio_output_configuration_changeset/2)
  end

  defp audio_decoder_configuration_changeset(module, attrs) do
    cast(module, attrs, [:reference_token, :name, :use_count])
  end

  defp audio_output_configuration_changeset(module, attrs) do
    cast(module, attrs, [
      :reference_token,
      :name,
      :use_count,
      :output_token,
      :send_primacy,
      :output_level
    ])
  end
end
