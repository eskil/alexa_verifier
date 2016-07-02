defmodule AlexaVerifier do
  use Timex

  def verify(url \\ "https://s3.amazonaws.com/echo.api/../echo.api/echo-api-cert.pem") do
    url = normalize(url)
    case verify_uri(url) do
      false -> false
      true ->
        cert_info = url |> get_cert |> get_cert_info
        IO.puts inspect(cert_info)
        case verify_cert_dates(cert_info) and verify_cert_subject(cert_info) do
          true -> true
          false -> false
        end
    end
  end

  def verify_cert_dates(%{"notBefore" => not_before, "notAfter" => not_after}) do
    {:ok, not_before} = Timex.parse(not_before, "%b %d %H:%M:%S %Y GMT", :strftime)
    {:ok, not_after} = Timex.parse(not_after, "%b %d %H:%M:%S %Y GMT", :strftime)
    Timex.between?(DateTime.today, not_before, not_after)
  end

  def verify_cert_subject(%{"subject" => subject}) do
    String.contains?(subject, "echo-api.amazon.com")
  end
  def verify_cert_subject(_), do: false

  def verify_uri(url) when is_binary(url), do: verify_uri(URI.parse(url))
  def verify_uri(%{scheme: "https", host: "s3.amazonaws.com", path: "/echo.api/"<>_, port: 443} = uri), do: true
  def verify_uri(_), do: false

  def normalize(url) do
    [first|parts] = String.split(url, "../")
    Enum.reduce(parts, URI.parse(first), fn(p, a) -> URI.merge(a, "../#{p}") end)
    |> URI.to_string
  end

  def get_cert(url) do
    %HTTPoison.Response{body: certs} = HTTPoison.get!(url)
    certs
  end

  def get_cert_info(cert) do
    %{out: result} = Porcelain.exec("openssl", ["x509", "-noout", "-issuer", "-subject", "-dates"], in: cert)
    parse_cert_info(result)
  end

  def parse_cert_info(cert_info) do
    cert_info
      |> String.split("\n", trim: true)
      |> Enum.map(fn(line) -> String.split(line, "=", parts: 2, trim: true) |> List.to_tuple end)
      |> Map.new
  end

end
