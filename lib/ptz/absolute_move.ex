defmodule ExOnvif.PTZ.AbsoluteMove do
  @moduledoc """
  Schema describing the absolute move request to the PTZ service.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import ExOnvif.Utils.XmlBuilder

  alias ExOnvif.PTZ.Vector

  @type t :: %__MODULE__{}
  @type vector :: {float(), float(), float()}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field :profile_token, :string
    embeds_one :position, Vector
    embeds_one :speed, Vector
  end

  @doc """
  Creates a new absolute move request.

  ## Parameters
    - `profile_token` - The token of the profile to move.
    - `position` - The position to move to, represented as a `Vector`.
    - `speed` - The speed of the move, represented as a `Vector`. Optional.
  """
  @spec new(String.t(), Vector.t(), Vector.t() | nil) :: t()
  @spec new(String.t(), Vector.t()) :: t()
  def new(profile_token, position, speed \\ nil) do
    %__MODULE__{
      profile_token: profile_token,
      position: position,
      speed: speed
    }
  end

  def encode(%__MODULE__{} = absolute_move) do
    element(
      "tptz:AbsoluteMove",
      element("tptz:ProfileToken", absolute_move.profile_token)
      |> element("tptz:Position", Vector.encode(absolute_move.position))
      |> element("tptz:Speed", Vector.encode(absolute_move.speed))
    )
  end

  def changeset(absolute_move, attrs) do
    absolute_move
    |> cast(attrs, [:profile_token])
    |> cast_embed(:position)
    |> cast_embed(:speed)
    |> validate_required([:profile_token])
  end
end
