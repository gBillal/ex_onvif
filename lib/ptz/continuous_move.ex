defmodule ExOnvif.PTZ.ContinuousMove do
  @moduledoc """
  Schema describing the continuous move request to the PTZ service.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import ExOnvif.Utils.XmlBuilder

  alias ExOnvif.PTZ.Vector

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field :profile_token, :string
    embeds_one :velocity, Vector
  end

  @doc """
  Creates a new continuous move request.

  ## Parameters
    - `profile_token` - The token of the profile to move.
    - `velocity` - The velocity to move at, represented as a `Vector`.
  """
  @spec new(String.t(), Vector.t()) :: t()
  def new(profile_token, velocity) do
    %__MODULE__{
      profile_token: profile_token,
      velocity: velocity
    }
  end

  def encode(%__MODULE__{} = continuous_move) do
    # Build in reverse order since element() prepends to list
    # We want: ProfileToken, Velocity
    # So build: Velocity, ProfileToken
    base =
      []
      |> element("tptz:Velocity", nil, Vector.encode(continuous_move.velocity))
      |> element("tptz:ProfileToken", nil, continuous_move.profile_token)

    element("tptz:ContinuousMove", base)
  end

  def changeset(continuous_move, attrs) do
    continuous_move
    |> cast(attrs, [:profile_token])
    |> cast_embed(:velocity)
    |> validate_required([:profile_token])
  end
end
