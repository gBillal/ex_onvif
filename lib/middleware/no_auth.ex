defmodule ExOnvif.Middleware.NoAuth do
  @moduledoc false

  @behaviour Tesla.Middleware

  @standard_namespaces [
    "xmlns:s": "http://www.w3.org/2003/05/soap-envelope"
  ]

  @impl Tesla.Middleware
  def call(env, next, _opts) do
    body =
      env.body
      |> ExOnvif.Request.add_namespaces(@standard_namespaces)
      |> ExOnvif.Request.encode()

    env |> Tesla.put_body(body) |> Tesla.run(next)
  end
end
