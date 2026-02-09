defmodule ExOnvif.PTZ.Presets do
  use Ecto.Schema

  import Ecto.Changeset
  import ExOnvif.Utils.XmlBuilder

  alias ExOnvif.PTZ.Vector

  @type t :: %__MODULE__{}

  @type preset_t :: %{
          profile_token: String.t(),
          preset_token: String.t(),
          speed: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    field :token, :string
    field :name, :string
    embeds_one :ptz_position, Vector
  end

  @spec new(String.t(), String.t(), Vector.t() | nil) :: preset_t()
  @spec new(String.t(), String.t()) :: preset_t()
  def new(profile_token, preset_token, speed \\ nil) do
    %{
      profile_token: profile_token,
      preset_token: preset_token,
      speed: speed
    }
  end

  def encode(preset) do
    base =
      if preset.speed do
        element("tptz:Speed", Vector.encode(preset.speed))
      else
        []
      end

    base =
      base
      |> element("tptz:PresetToken", nil, preset.preset_token)
      |> element("tptz:ProfileToken", nil, preset.profile_token)

    element("tptz:GotoPreset", base)
  end

  def to_struct(presets) do
    presets
    |> Enum.map(fn preset ->
      {:ok, pres} =
        %__MODULE__{}
        |> changeset(preset)
        |> apply_action(:validate)

      pres
    end)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, __MODULE__.__schema__(:fields) -- [:ptz_position])
    |> cast_embed(:ptz_position, with: &Vector.changeset/2)
  end
end
