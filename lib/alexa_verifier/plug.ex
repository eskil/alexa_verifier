defmodule AlexaVerifier.Plug do
  use Plug.Builder
  import AlexaVerifier

  @certificate_url_header "signaturecertchainurl"
  @signature_header "signature"
  @verifier_client Application.get_env(:alexa_verifier, :verifier_client)

  plug :verify_request

  defp certificate_url(conn) do
    get_req_header(conn, @certificate_url_header) |> List.first
  end

  defp signature(conn) do
    get_req_header(conn, @signature_header) |> List.first
  end

  defp request_body(conn) do
    case conn.private[:raw_body] do
      nil ->
        {:ok, body, _} = read_body(conn)
        body
      raw_body ->
        raw_body
    end
  end

  def verify_request(conn, _) do
    case @verifier_client.verify(request_body(conn), signature(conn), certificate_url(conn)) do
      :ok -> conn
      :error -> conn |> send_resp(400, "Invalid Alexa Signature") |> halt
    end
  end

end
