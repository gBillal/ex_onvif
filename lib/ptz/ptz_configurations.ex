defmodule ExOnvif.PTZ.PTZConfigurations do

  alias ExOnvif.Schemas.{Space2DDescription,Space1DDescription}

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

  # Ramps
  field :move_ramp, :integer
  field :preset_ramp, :integer
  field :preset_tour_ramp, :integer

  # Node reference
  field :node_token, :string

  # Default coordinate spaces
  field :default_absolute_pan_tilt_position_space, :string
  field :default_absolute_zoom_position_space, :string
  field :default_relative_pan_tilt_translation_space, :string
  field :default_relative_zoom_translation_space, :string
  field :default_continuous_pan_tilt_velocity_space, :string
  field :default_continuous_zoom_velocity_space, :string

  # Defaults
  embeds_one :default_ptz_speed, ExOnvif.PTZ.Vector 
  field :default_ptz_timeout, :string

# Limits
  embeds_one :pan_tilt_limits, Space2DDescription 
  embeds_one :zoom_limits, Space1DDescription 

  # Extensions
  embeds_one :extension, Extension, primary_key: false do
    embeds_one :extension, PTControlDirection
  end


  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, __MODULE__.__schema__(:fields))
  end

  def parse(doc) do
    xmap(
      doc,
      token: ~x"./@token"s,
      name: ~x"./tty:name",
      use_count: ~x"./tt:UseCount/text()"s,
      move_ramp: ~x"./tt:MoveRamp/text()"s,
      present_ramp: ~x"./tt:PresentRamp/text()"s,
      node_token: ~x"./tt:NodeToken/text()"s,
      default_absolute_pan_tilt_position_space:
      ~x"./tt:DefaultAbsolutePantTiltPositionSpace/text()"s,

      default_absolute_zoom_position_space:
      ~x"./tt:DefaultAbsoluteZoomPositionSpace/text()"s,

      default_relative_pan_tilt_translation_space:
      ~x"./tt:DefaultRelativePanTiltTranslationSpace/text()"s,

      default_relative_zoom_translation_space:
      ~x"./tt:DefaultRelativeZoomTranslationSpace/text()"s,

      default_continuous_pan_tilt_velocity_space:
      ~x"./tt:DefaultContinuousPanTiltVelocitySpace/text()"s,

      default_continuous_zoom_velocity_space:
      ~x"./tt:DefaultContinuousZoomVelocitySpace/text()"s
    )
  end
end
