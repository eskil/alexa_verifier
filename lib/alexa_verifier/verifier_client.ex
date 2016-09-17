defmodule AlexaVerifier.VerifierClient do
  use HTTPoison.Base

  defp process_url(url) do
    Application.get_env(:alexa_verifier, :verifier_service_url) <> url
  end

  def verify(_, nil, nil) do
    :ok
  end

  def verify(request_body, signature, cert_url) do
    headers = [
      {"Content-Type", "appliction/json"},
      {"signaturecertchainurl", cert_url},
      {"signature", signature}
    ]
    case RiverPlace.post!("/verify", request_body, headers) do
      %{body: "success"} ->
        :ok
      _ ->
        :error
    end
  end

end
