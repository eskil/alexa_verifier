defmodule AlexaVerifier.CertCache do

  @agent_name :alexa_certs

  def start_link do
    Agent.start_link(fn -> %{} end, name: @agent_name)
  end

  def get(url) do
    case Agent.get(@agent_name, &Map.get(&1, url)) do
      nil ->
        %{body: cert} = HTTPoison.get!(url)
        put(url, cert)
        cert
      cert -> cert
    end
  end

  def put(url, cert) do
    Agent.update(@agent_name, &Map.put(&1, url, cert))
  end

end
