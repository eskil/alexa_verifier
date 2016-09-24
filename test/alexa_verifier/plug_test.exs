defmodule AlexaVerifier.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @cert_url_header "signaturecertchainurl"
  @signature_header "signature"
  @opts AlexaVerifier.Plug.init([])

  def create_conn(body, cert_url, signature) do
    conn(:post, "https://www.example.com/command", body)
      |> put_req_header(@cert_url_header, cert_url)
      |> put_req_header(@signature_header, signature)
  end

  test "successful validation" do
    conn = create_conn("{}", "http://www.example.com/cert.pem", "success")
    conn = AlexaVerifier.Plug.call(conn, @opts)
    refute conn.status == 400
    refute conn.halted
  end

  test "failed validation" do
    conn = create_conn("{}", "http://www.example.com/cert.pem", "failure")
    conn = AlexaVerifier.Plug.call(conn, @opts)
    assert conn.status == 400
    assert conn.resp_body == "Invalid Alexa Signature"
    assert conn.halted
  end
end
