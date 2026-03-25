defmodule ExOnvif.PTZ.SetPreset do
  use Ecto.Schema
  import SweetXml

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :preset_token, :string
  end

  def parse(doc) do
    xmap(doc,
      preset_token: ~x"//tptz:SetPresetResponse/tptz:PresetToken/text()"s
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  defp changeset(module, attr) do
    module
    |> cast(attr, [:preset_token])
  end
end
