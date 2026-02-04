defmodule ExOnvif.PTZ.Presets do
  use Ecto.Schema

  import Ecto.Changeset

  alias ExOnvif.PTZ.Vector

  @type t :: %__MODULE__{}


  @primary_key false
  embedded_schema do
      field :token, :string
      field :name, :string
      embeds_one :ptz_position, Vector
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
