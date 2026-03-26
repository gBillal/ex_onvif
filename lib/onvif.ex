defmodule ExOnvif do
  @moduledoc """
  Interface for making requests to an Onvif compatible device.

  Currently supports WS Discovery probing, a subset of Device wsdl functions
  and a subset of Media wsdl functions.
  """

  @type error ::
          {:error, ExOnvif.Fault.t()} | {:error, %{status: non_neg_integer(), response: any()}}
end
