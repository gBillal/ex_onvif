defmodule ExOnvif.PTZ.Stop do
  @moduledoc """
  Schema describing the stop request to the PTZ service.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import ExOnvif.Utils.XmlBuilder

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field :profile_token, :string
    field :pan_tilt, :boolean
    field :zoom, :boolean
  end

  @doc """
  Creates a new stop request.

  ## Parameters
    - `profile_token` - The token of the profile to stop.
    - `pan_tilt` - Whether to stop pan/tilt movement (default: true).
    - `zoom` - Whether to stop zoom movement (default: true).
  """
  @spec new(String.t(), boolean(), boolean()) :: t()
  @spec new(String.t(), boolean()) :: t()
  @spec new(String.t()) :: t()
  def new(profile_token, pan_tilt \\ true, zoom \\ true) do
    %__MODULE__{
      profile_token: profile_token,
      pan_tilt: pan_tilt,
      zoom: zoom
    }
  end

  def encode(%__MODULE__{} = stop) do
    base =
      []
      |> element("tptz:Zoom", nil, to_string(stop.zoom))
      |> element("tptz:PanTilt", nil, to_string(stop.pan_tilt))
      |> element("tptz:ProfileToken", nil, stop.profile_token)

    element("tptz:Stop", base)
  end

  def changeset(stop, attrs) do
    stop
    |> cast(attrs, [:profile_token, :pan_tilt, :zoom])
    |> validate_required([:profile_token])
  end
end
