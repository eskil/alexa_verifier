defmodule AlexaVerifierTest do
  use ExUnit.Case
  doctest AlexaVerifier

  test "verify_uri" do
    assert AlexaVerifier.verify_uri("https://s3.amazonaws.com/echo.api/echo-api-cert.pem")
    assert AlexaVerifier.verify_uri("https://s3.amazonaws.com:443/echo.api/echo-api-cert.pem")
    assert AlexaVerifier.verify_uri("https://s3.amazonaws.com/echo.api/../echo.api/echo-api-cert.pem")

    assert false == AlexaVerifier.verify_uri("http://s3.amazonaws.com/echo.api/echo-api-cert.pem")
    assert false == AlexaVerifier.verify_uri("https://notamazon.com/echo.api/echo-api-cert.pem")
    assert false == AlexaVerifier.verify_uri("https://s3.amazonaws.com/EcHo.aPi/echo-api-cert.pem")
    assert false == AlexaVerifier.verify_uri("https://s3.amazonaws.com/invalid.path/echo-api-cert.pem")
    assert false == AlexaVerifier.verify_uri("https://s3.amazonaws.com:563/echo.api/echo-api-cert.pem")
  end

  test "normalize" do
    assert "http://example.com/def/index.html" == AlexaVerifier.normalize("http://example.com/abc/../def/index.html")
  end

  test "verify_cert_dates with valid notBefore and notAfter dates" do
    cert_info = %{"notAfter" => "Oct 31 23:59:59 2020 GMT", "notBefore" => "Feb 14 01:02:03 2013 GMT"}
    assert AlexaVerifier.verify_cert_dates(cert_info)
  end

  test "verify_cert_dates with an expired notAfter date" do
    cert_info = %{"notAfter" => "Oct 31 23:59:59 2015 GMT", "notBefore" => "Jan 31 00:00:00 2015 GMT"}
    assert false == AlexaVerifier.verify_cert_dates(cert_info)
  end

  test "verify_cert_dates with an invalid notBefore date" do
    cert_info = %{"notAfter" => "Oct 31 23:59:59 2020 GMT", "notBefore" => "Jan 31 00:00:00 2019 GMT"}
    assert false == AlexaVerifier.verify_cert_dates(cert_info)
  end

  test "verify_cert_subject when valid" do
    cert_info = %{"subject" => " /C=US/ST=Washington/L=Seattle/O=Amazon.com, Inc./CN=echo-api.amazon.com"}
    assert AlexaVerifier.verify_cert_subject(cert_info)
  end

  test "verify_cert_subject when invalid" do
    cert_info = %{"subject" => " /C=US/ST=Washington/L=Seattle/O=Amazon.com"}
    assert false == AlexaVerifier.verify_cert_subject(cert_info)
  end

  test "verify_cert_subject when subject missing" do
    cert_info = %{}
    assert false == AlexaVerifier.verify_cert_subject(cert_info)
  end

  test "verify_cert with valid signature" do
    assert AlexaVerifier.verify_cert("", "YWJjZGVmZ2hpamtsbW5vcA==")
  end

  test "verify_cert with invalid signature" do
    assert false == AlexaVerifier.verify_cert("", "not-valid-Base64")
  end

end
