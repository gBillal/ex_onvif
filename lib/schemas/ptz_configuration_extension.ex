defmodule ExOnvif.Schemas.PTControlDirection do
  use Ecto.Schema

  embedded_schema do
    embeds_one :e_flip, EFlip, primary_key: false do
      field :mode, Ecto.Enum, values: [:OFF, :ON, :Extended]
    end
    embeds_one :reverse, Reverse, primary_key: false do
      field :mode, Ecto.Enum, values: [:OFF, :ON, :Extended]
    end
  end
end
