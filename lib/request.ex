defmodule ExOnvif.Request do
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

    def encode(%__MODULE__{auth: nil, subscription_id: nil}), do: nil

    def encode(%__MODULE__{} = header) do
      element(
        :"s:Header",
        encode_subscription_id([], header.subscription_id) |> encode_auth(header.auth)
      )
    end

    defp encode_auth(content, nil), do: content
    defp encode_auth(content, auth), do: [auth | content]

    defp encode_subscription_id(content, nil), do: content

    defp encode_subscription_id(content, subscription_id) do
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

    iex> request = %ExOnvif.Request{content: "content"}
    iex> ExOnvif.Request.put_header(request, :subscription_id, "15")
    %ExOnvif.Request{content: "content", namespaces: [], header: %ExOnvif.Request.Header{subscription_id: "15"}}

  """
  @spec put_header(t(), atom(), any()) :: t()
  def put_header(%__MODULE__{header: header} = request, key, value) do
    new_header = Map.put(header || %Header{}, key, value)
    %{request | header: new_header}
  end

  @doc """
  Add namespaces to the request.

    iex> request = %ExOnvif.Request{content: "content"}
    iex> request = ExOnvif.Request.add_namespaces(request, ["xmlns:wsse": "http://www.w3.org/2003/05/soap-envelope"])
    %ExOnvif.Request{content: "content", namespaces: ["xmlns:wsse": "http://www.w3.org/2003/05/soap-envelope"]}
    iex> ExOnvif.Request.add_namespaces(request, ["xmlns:wsa": "http://www.w3.org/2005/08/addressing"])
    %ExOnvif.Request{content: "content", namespaces: ["xmlns:wsa": "http://www.w3.org/2005/08/addressing", "xmlns:wsse": "http://www.w3.org/2003/05/soap-envelope"]}
  """
  @spec add_namespaces(t(), list()) :: t()
  def add_namespaces(%__MODULE__{namespaces: cur_namespaces} = request, namespaces) do
    %__MODULE__{request | namespaces: namespaces ++ cur_namespaces}
  end

  @doc """
  Serializes the request to a string.

    iex> request = %ExOnvif.Request{content: "content", namespaces: ["xmlns:s": "http://www.w3.org/2003/05/soap-envelope"]}
    iex> ExOnvif.Request.encode(request)
    "<s:Envelope xmlns:s=\\"http://www.w3.org/2003/05/soap-envelope\\">\\n  content\\n</s:Envelope>"
  """
  @spec encode(t()) :: String.t()
  def encode(%__MODULE__{} = request) do
    generate(
      element(
        :"s:Envelope",
        request.namespaces,
        [request.header && Header.encode(request.header), request.content]
      )
    )
  end
end
