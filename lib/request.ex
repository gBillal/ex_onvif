defmodule Onvif.Request do
  @moduledoc """
  Module describing an onvif request.
  """

  import XmlBuilder

  defmodule Header do
    @moduledoc """
    Struct describing onvif headers
    """

    import XmlBuilder

    @type t :: %__MODULE__{
            auth: any(),
            subscription_id: String.t()
          }

    defstruct [:auth, :subscription_id]

    def serialize(%__MODULE__{auth: nil, subscription_id: nil}), do: nil

    def serialize(%__MODULE__{} = header) do
      element(
        :"s:Header",
        serialize_subscription_id([], header.subscription_id) |> serialize_auth(header.auth)
      )
    end

    defp serialize_auth(content, nil), do: content
    defp serialize_auth(content, auth), do: [auth | content]

    defp serialize_subscription_id(content, nil), do: content

    defp serialize_subscription_id(content, subscription_id) do
      [
        element(
          "dom0:SubscriptionId",
          %{"xmlns:dom0" => "http://www.axis.com/2009/event"},
          subscription_id
        )
        | content
      ]
    end
  end

  @type t :: %__MODULE__{
          content: any(),
          namespaces: list(),
          header: Header.t()
        }

  defstruct [:content, namespaces: [], header: nil]

  @doc """
  Puts a new header in the request.

    iex> request = %Onvif.Request{content: "content"}
    iex> Onvif.Request.put_header(request, :subscription_id, "15")
    %Onvif.Request{content: "content", namespaces: [], header: %Onvif.Request.Header{subscription_id: "15"}}

  """
  @spec put_header(t(), atom(), any()) :: t()
  def put_header(%__MODULE__{header: header} = request, key, value) do
    new_header = Map.put(header || %Header{}, key, value)
    %{request | header: new_header}
  end

  @doc """
  Add namespaces to the request.

    iex> request = %Onvif.Request{content: "content"}
    iex> request = Onvif.Request.add_namespaces(request, ["xmlns:wsse": "http://www.w3.org/2003/05/soap-envelope"])
    %Onvif.Request{content: "content", namespaces: ["xmlns:wsse": "http://www.w3.org/2003/05/soap-envelope"]}
    iex> Onvif.Request.add_namespaces(request, ["xmlns:wsa": "http://www.w3.org/2005/08/addressing"])
    %Onvif.Request{content: "content", namespaces: ["xmlns:wsa": "http://www.w3.org/2005/08/addressing", "xmlns:wsse": "http://www.w3.org/2003/05/soap-envelope"]}
  """
  @spec add_namespaces(t(), list()) :: t()
  def add_namespaces(%__MODULE__{namespaces: cur_namespaces} = request, namespaces) do
    %__MODULE__{request | namespaces: namespaces ++ cur_namespaces}
  end

  @doc """
  Serializes the request to a string.

    iex> request = %Onvif.Request{content: "content", namespaces: ["xmlns:s": "http://www.w3.org/2003/05/soap-envelope"]}
    iex> Onvif.Request.serialize(request)
    "<s:Envelope xmlns:s=\\"http://www.w3.org/2003/05/soap-envelope\\">\\n  content\\n</s:Envelope>"
  """
  @spec serialize(t()) :: String.t()
  def serialize(%__MODULE__{} = request) do
    generate(
      element(
        :"s:Envelope",
        request.namespaces,
        [request.header && Header.serialize(request.header), request.content]
      )
    )
  end
end
