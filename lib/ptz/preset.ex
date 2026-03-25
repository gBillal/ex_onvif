defmodule ExOnvif.PTZ.Preset do
  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  alias ExOnvif.PTZ.Vector

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :token, :string
    field :name, :string
    embeds_one :position, Vector
  end

  @spec new(String.t(), String.t(), Vector.t() | nil) :: t()
  @spec new(String.t(), String.t()) :: t()
  def new(profile_token, preset_token, speed \\ nil) do
    %{
      profile_token: profile_token,
      preset_token: preset_token,
      speed: speed
    }
  end

  def parse(preset) do
    xmap(
      preset,
      token: ~x"./@token"s,
      name: ~x"./tt:Name/text()"s,
      position: ~x"./tt:PTZPosition"o |> transform_by(&Vector.parse/1)
    )
  end

  def to_struct(preset) do
    %__MODULE__{}
    |> changeset(preset)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:token, :name])
    |> cast_embed(:position, with: &Vector.changeset/2)
  end
end
