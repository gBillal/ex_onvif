defmodule ExOnvif.PTZ.HomePosition do

  alias ExOnvif.PTZ.Vector

  import ExOnvif.Utils.XmlBuilder

  @type t :: %__MODULE__{
    profile_token: String.t(),
    speed: Vector.t()
  }

  defstruct [
    :profile_token,
    :speed
  ]

  @spec new(String.t(), Vector.t()) :: t()
  @spec new(String.t()) :: t()
  def new(profile_token, speed \\ nil) do
    %__MODULE__{
      profile_token: profile_token,
      speed: speed
    }
  end

  def encode(%__MODULE__{} = home_position) do
    base = 
      if home_position.speed do
        element("tptz:Speed", Vector.encode(home_position.speed))
      else
      []
      end

    base = 
      base 
      |> element("tptz:ProfileToken", nil, home_position.profile_token)

    element("tptz:GotoHomePosition", base)
  end

end
