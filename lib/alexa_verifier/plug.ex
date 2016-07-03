defmodule AlexaVerifier.Plug do
  use Plug.Builder
  import AlexaVerifier
  require Logger

  @certificate_url_header "signaturecertchainurl"
  @signature_header "signature"

  plug :verify_cert_url
  plug :get_cert
  plug :verify_certificate
  plug :verify_request

  def verify_cert_url(conn, _) do
    cert_url = certificate_url(conn)
    Logger.debug("Cert URL: #{cert_url}")
    case verify_uri(cert_url) do
      true -> conn
      false ->
        Logger.info("Invalid Alexa Signature URL")
        conn |> send_resp(400, "Invalid Alexa Signature URL") |> halt
    end
  end

  def get_cert(conn, _) do
    cert = AlexaVerifier.CertCache.get(certificate_url(conn))
    Logger.debug("Cert: #{cert}")
    put_private(conn, :alexa_verifier_cert, cert)
  end

  def verify_certificate(conn, _) do
    cert = conn.private[:alexa_verifier_cert]
    cert_info = get_cert_info(cert)
    Logger.debug("Cert Info: #{inspect(cert_info)}")
    case verify_cert_dates(cert_info) and verify_cert_subject(cert_info) do
      true -> conn
      false ->
        Logger.info("Invalid Alexa Signature Certificate")
        conn |> send_resp(400, "Invalid Alexa Signature Certificate") |> halt
    end
  end

  def verify_request(conn, _) do
    cert = conn.private[:alexa_verifier_cert]
    Logger.debug("Signature Header: #{signature(conn)}")
    signature_hash = signature(conn) |> decrypt_signature(cert)
    Logger.debug("Signature Hash: #{signature_hash}")
    hash = request_hash(conn)
    Logger.debug("Request Hash: #{hash}")
    case signature_hash == hash do
      true -> conn
      false ->
        Logger.info("Invalid Alexa Signature")
        conn |> send_resp(400, "Invalid Alexa Signature") |> halt
    end
  end

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

  defp request_hash(conn) do
    raw_body = request_body(conn)
    Logger.debug("Raw Request Body: #{raw_body}")
    sha1(raw_body) |> Base.encode16(case: :lower)
  end

  defp sha1(data) do
    :crypto.hash(:sha, data)
  end

end
