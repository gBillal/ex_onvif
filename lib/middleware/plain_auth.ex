defmodule Onvif.Middleware.PlainAuth do
  @moduledoc false

  @behaviour Tesla.Middleware
  import XmlBuilder

  alias Onvif.Request

  @security_header_namespaces [
    "xmlns:wsse":
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext1.0.xsd"
  ]

  @standard_namespaces [
    "xmlns:s": "http://www.w3.org/2003/05/soap-envelope"
  ]

  @impl Tesla.Middleware
  def call(env, next, opts) do
    body = inject_xml_auth_header(env, opts)
    env |> Tesla.put_body(body) |> Tesla.run(next)
  end

  defp inject_xml_auth_header(env, opts) do
    case generate_xml_auth_header(opts) do
      nil ->
        env.body
        |> Request.add_namespaces(@standard_namespaces)
        |> Request.encode()

      auth_header ->
        env.body
        |> Request.add_namespaces(@standard_namespaces)
        |> Request.add_namespaces(@security_header_namespaces)
        |> Request.put_header(:auth, auth_header)
        |> Request.encode()
    end
  end

  defp generate_xml_auth_header(device: device) do
    element(
      :"wsse:Security",
      [
        element(
          :"wsse:UsernameToken",
          [
            element(:"wsse:Username", device.username),
            element(
              :"wsse:Password",
              %{
                "Type" =>
                  "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"
              },
              device.password
            )
          ]
        )
      ]
    )
  end

  defp generate_xml_auth_header(_uri), do: nil
end
