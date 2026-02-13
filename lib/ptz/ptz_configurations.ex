defmodule ExOnvif.PTZ.Configurations do
  alias ExOnvif.Schemas.{Space2DDescription, Space1DDescription, PTControlDirection}
  alias ExOnvif.PTZ.Vector

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder

  embedded_schema do
    field :token, :string
    field :name, :string
    field :use_count, :integer

    field :move_ramp, :integer
    field :present_ramp, :integer
    field :preset_tour_ramp, :integer

    field :node_token, :string

    field :default_absolute_pan_tilt_position_space, :string
    field :default_absolute_zoom_position_space, :string
    field :default_relative_pan_tilt_translation_space, :string
    field :default_relative_zoom_translation_space, :string
    field :default_continuous_pan_tilt_velocity_space, :string
    field :default_continuous_zoom_velocity_space, :string

    embeds_one :default_ptz_speed, Vector
    field :default_ptz_timeout, :string

    embeds_one :pan_tilt_limits, Space2DDescription
    embeds_one :zoom_limits, Space1DDescription

    embeds_one :extension, Extension, primary_key: false do
      embeds_one :pt_control_direction, PTControlDirection
    end
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(
      attrs,
      __MODULE__.__schema__(:fields) --
        [:default_ptz_speed, :pan_tilt_limits, :extension, :zoom_limits]
    )
    |> cast_embed(:default_ptz_speed, with: &Vector.changeset/2)
    |> cast_embed(:pan_tilt_limits, with: &Space2DDescription.changeset/2)
    |> cast_embed(:zoom_limits, with: &Space1DDescription.changeset/2)
    |> cast_embed(:extension, with: &extension_changeset/2)
  end

  def parse(doc) do
    xmap(
      doc,
      token: ~x"./@token"s,
      name: ~x"./tt:Name/text()"s,
      use_count: ~x"./tt:UseCount/text()"s,
      move_ramp: ~x"./tt:MoveRamp/text()"s,
      present_ramp: ~x"./tt:PresentRamp/text()"s,
      preset_tour_ramp: ~x"./tt:PresetTourRamp/text()"s,
      node_token: ~x"./tt:NodeToken/text()"s,
      default_ptz_timeout: ~x"./tt:DefaultPTZTimeout/text()"s,
      default_absolute_pan_tilt_position_space:
        ~x"./tt:DefaultAbsolutePantTiltPositionSpace/text()"s,
      default_absolute_zoom_position_space: ~x"./tt:DefaultAbsoluteZoomPositionSpace/text()"s,
      default_relative_pan_tilt_translation_space:
        ~x"./tt:DefaultRelativePanTiltTranslationSpace/text()"s,
      default_relative_zoom_translation_space:
        ~x"./tt:DefaultRelativeZoomTranslationSpace/text()"s,
      default_continuous_pan_tilt_velocity_space:
        ~x"./tt:DefaultContinuousPanTiltVelocitySpace/text()"s,
      default_continuous_zoom_velocity_space: ~x"./tt:DefaultContinuousZoomVelocitySpace/text()"s,
      extension: ~x"./tt:Extension"e |> transform_by(&parse_extension/1),
      pan_tilt_limits: ~x"./tt:PanTiltLimits"e |> transform_by(&parse_pan_tilt_limits/1),
      zoom_limits: ~x"./tt:ZoomLimits"e |> transform_by(&parse_zoom_limits/1),
      default_ptz_speed: ~x"./tt:DefaultPTZSpeed"e |> transform_by(&Vector.parse/1)
    )
  end

  defp extension_changeset(module, attrs) do
    module
    |> cast(attrs, [])
    |> cast_embed(:pt_control_direction, with: &PTControlDirection.changeset/2)
  end

  defp parse_pan_tilt_limits(nil), do: nil

  defp parse_pan_tilt_limits(doc) do
    xmap(
      doc,
      range: ~x"./tt:Range"e |> transform_by(&Space2DDescription.parse/1)
    )
  end

  defp parse_zoom_limits(nil), do: nil

  defp parse_zoom_limits(doc) do
    xmap(
      doc,
      range: ~x"./tt:Range"e |> transform_by(&Space1DDescription.parse/1)
    )
  end

  defp parse_extension(nil), do: nil

  defp parse_extension(doc) do
    xmap(
      doc,
      pt_control_direction:
        ~x"./tt:PTControlDirection"e |> transform_by(&PTControlDirection.parse/1)
    )
  end
end
