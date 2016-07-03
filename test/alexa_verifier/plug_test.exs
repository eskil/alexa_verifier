defmodule AlexaVerifier.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @signature_url_header "signaturecertchainurl"
  @signature_header "signature"
  @request_body File.read!("test/data/request.json")
  @valid_url "https://s3.amazonaws.com/echo.api/echo-api-cert.pem"
  @valid_signature File.read!("test/data/request_hash.sign")
  @opts AlexaVerifier.Plug.init([])

  setup do
    AlexaVerifier.CertCache.start_link
    :ok
  end

  def create_conn(signature_url \\ @valid_url, body \\ @request_body) do
    conn(:post, "https://www.example.com/command", body)
      |> put_req_header(@signature_url_header, signature_url)
      |> put_req_header(@signature_header, @valid_signature)
  end

  test "returns error when certificate url is blank" do
    conn = conn(:post, "https://www.example.com/command", @request_body)
    conn = AlexaVerifier.Plug.call(conn, @opts)
    assert conn.status == 400
    assert conn.resp_body == "Invalid Alexa Signature URL"
    assert conn.halted
  end

  # Test plug :verify_url

  test "does nothing when url is valid" do
    conn = create_conn
    conn = AlexaVerifier.Plug.verify_cert_url(conn, @opts)
    assert conn.state == :unset
  end

  test "returns error when url is not valid" do
    conn = create_conn("https://s3.amazonaws.com/hello.pem")
    conn = AlexaVerifier.Plug.verify_cert_url(conn, @opts)
    assert conn.status == 400
    assert conn.resp_body == "Invalid Alexa Signature URL"
    assert conn.halted
  end

  # Test plug :get_cert

  test "downloads the cert and stores it in connection" do
    expected_cert = "sample-cert"
    AlexaVerifier.CertCache.put(@valid_url, expected_cert)
    conn = create_conn
    conn = AlexaVerifier.Plug.get_cert(conn, @opts)
    assert conn.private[:alexa_verifier_cert] == expected_cert
  end

  # Test plug :verify_certificate

  test "does nothing when cert is valid" do
    valid_cert = File.read!("test/data/cert.pem")
    conn = create_conn |> put_private(:alexa_verifier_cert, valid_cert)
    conn = AlexaVerifier.Plug.verify_certificate(conn, @opts)
    assert conn.state == :unset
  end

  test "returns error when certificate is not valid" do
    invalid_cert = File.read!("test/data/echo-api-cert.pem")
    conn = create_conn |> put_private(:alexa_verifier_cert, invalid_cert)
    conn = AlexaVerifier.Plug.verify_certificate(conn, @opts)
    assert conn.status == 400
    assert conn.resp_body == "Invalid Alexa Signature Certificate"
    assert conn.halted
  end

  # Test plug :verify_request

  test "does nothing when signature matches the request" do
    valid_cert = File.read!("test/data/cert.pem")
    conn = create_conn |> put_private(:alexa_verifier_cert, valid_cert)
    conn = AlexaVerifier.Plug.verify_request(conn, @opts)
    assert conn.state == :unset
  end

  test "returns error when signature does not match request" do
    valid_cert = File.read!("test/data/cert.pem")
    conn = create_conn(@valid_url, "unmatched request body")
      |> put_private(:alexa_verifier_cert, valid_cert)
    conn = AlexaVerifier.Plug.verify_request(conn, @opts)
    assert conn.status == 400
    assert conn.resp_body == "Invalid Alexa Signature"
    assert conn.halted
  end

end
