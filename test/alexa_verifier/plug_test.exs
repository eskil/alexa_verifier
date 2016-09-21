defmodule AlexaVerifier.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @cert_url_header "signaturecertchainurl"
  @signature_header "signature"
  @opts AlexaVerifier.Plug.init([])

  setup do
    AlexaVerifier.CertCache.start_link
    :ok
  end

  def create_conn(body, cert_url, signature) do
    conn(:post, "https://www.example.com/command", body)
      |> put_req_header(@cert_url_header, cert_url)
      |> put_req_header(@signature_header, signature)
  end

end
