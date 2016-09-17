defmodule AlexaVerifier.VerifierClient do
  use HTTPoison.Base

  defp process_url(url) do
    result = Application.get_env(:alexa_verifier, :verifier_service_url) <> url
    IO.puts "Verifier URL = #{result}"
    result
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
    IO.puts "Sending verification request..."
    case AlexaVerifier.VerifierClient.post!("/verify", request_body, headers) do
      %{status_code: 200} ->
        IO.puts "Verification successful"
        :ok
      response ->
        IO.puts "Verification failed"
        IO.puts "Response = #{inspect(response)}"
        :error
    end
  end

end
