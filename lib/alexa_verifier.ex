defmodule AlexaVerifier do
  use Timex

  def start_link do
    AlexaVerifier.CertCache.start_link
  end

  def start(:normal, []) do
    AlexaVerifier.CertCache.start_link
  end

  def verify_cert_dates(%{"notBefore" => not_before, "notAfter" => not_after}) do
    {:ok, not_before} = Timex.parse(not_before, "%b %e %H:%M:%S %Y GMT", :strftime)
    {:ok, not_after} = Timex.parse(not_after, "%b %e %H:%M:%S %Y GMT", :strftime)
    # TODO: temporary. Remove soon!
    not_before = Timex.shift(not_before, days: -1)
    Timex.between?(DateTime.today, not_before, not_after)
  end

  def verify_cert_subject(%{"subject" => subject}) do
    String.contains?(subject, "echo-api.amazon.com")
  end
  def verify_cert_subject(_), do: false

  def verify_uri(url) when is_binary(url), do: verify_uri(URI.parse(url))
  def verify_uri(%{scheme: "https", host: "s3.amazonaws.com", path: "/echo.api/"<>_, port: 443}), do: true
  def verify_uri(_), do: false

  def normalize(url) do
    [first|parts] = String.split(url, "../")
    Enum.reduce(parts, URI.parse(first), fn(p, a) -> URI.merge(a, "../#{p}") end)
    |> URI.to_string
  end

  def get_cert_info(cert) do
    %{out: result} = Porcelain.exec("openssl", ["x509", "-noout", "-issuer", "-subject", "-dates"], in: cert)
    parse_cert_info(result)
  end

  def decrypt_signature(signature, cert) do
    # TODO: find a way to do this without having to write to file first!
    signature = Base.decode64!(signature, ignore: :whitespace)
    File.write!("/tmp/tmp_signature", signature)
    File.write!("/tmp/tmp_cert.pem", cert)
    %{out: result} = Porcelain.exec("openssl", ["rsautl", "-verify", "-inkey", "/tmp/tmp_cert.pem", "-certin", "-in", "/tmp/tmp_signature"])
    String.trim(result)
  end

  def parse_cert_info(cert_info) do
    cert_info
      |> String.split("\n", trim: true)
      |> Enum.map(fn(line) -> String.split(line, "=", parts: 2, trim: true) |> List.to_tuple end)
      |> Map.new
  end

end
