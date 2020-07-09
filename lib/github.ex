defmodule DevDocs.GitHub do

  @content_type "application/vnd.github.machine-man-preview+json"
  @pages_content_type "  application/vnd.github.mister-fantastic-preview+json"

  defp config do
    :devdocs
    |> Application.get_env(DevDocs.GitHub)
    |> Keyword.merge([ site: "https://api.github.com" ])
  end

  def get_installations!(integration_token) do
    get_installations_!(
      integration_token,
      "#{config()[:site]}/app/installations",
      [])
  end

  defp get_installations_!(_, nil, repos) do
    repos
  end

  defp get_installations_!(integration_token, url, append) do
    params = case URI.parse(url).query do
      nil -> []
      qry -> URI.query_decoder(qry) |> Enum.to_list()
    end
    %{body: raw, status_code: 200, headers: headers} = HTTPoison.get!(
      url,
      [
        {"Authorization", "Bearer #{integration_token}"},
        {"Accept", @content_type}],
      [params: params])
    l = Poison.decode!(raw)
    |> Enum.map(&(&1["id"]))
    |> Enum.concat(append)
    next_headers = headers
    |> Enum.filter(&(elem(&1, 0) == "Link"))
    |> Enum.map(&(ExLinkHeader.parse!(elem(&1, 1))))
    |> Enum.filter(&!is_nil(&1.next))
    case next_headers do
      [] -> l
      [next] -> get_installations_!(integration_token, next.next.url, l)
    end
  end

  def get_installation_repos!(token) do
    get_installation_repos_!(
      token,
      "#{config()[:site]}/installation/repositories",
      [])
  end

  defp get_installation_repos_!(_, nil, repos) do
    repos
  end

  defp get_installation_repos_!(token, url, append) do
    params = case URI.parse(url).query do
      nil -> []
      qry -> URI.query_decoder(qry) |> Enum.to_list()
    end
    %{body: raw, status_code: 200, headers: headers} = HTTPoison.get!(
      url,
      [
        {"Authorization", "token #{token}"},
        {"Accept", @content_type}],
      [params: params])
    repositories = Poison.decode!(raw)["repositories"]
    |> Enum.concat(append)
    next_headers = headers
    |> Enum.filter(&(elem(&1, 0) == "Link"))
    |> Enum.map(&(ExLinkHeader.parse!(elem(&1, 1))))
    |> Enum.filter(&!is_nil(&1.next))
    case next_headers do
      [] -> repositories
      [next] -> get_installation_repos_!(token, next.next.url, repositories)
    end
  end

  def trigger_pages_build!(token, id) do
    %{status_code: 201} = HTTPoison.post!(
      "#{config()[:site]}/repositories/#{id}/pages/builds",
      "",
      [
        {"Authorization", "token #{token}"},
        {"Accept", @pages_content_type}])
  end

  defp write_http_to_file(path) when is_binary(path) do
    {:ok, file} = File.open(path, [:write])
    write_http_to_file(file)
  end

  defp write_http_to_file(file) do
    receive do
      %HTTPoison.AsyncHeaders{headers: headers} ->
        loc = headers
        |> Enum.map(&get_redirect/1)
        |> Enum.filter(&(not is_nil &1))
        case loc do
          [] ->
            write_http_to_file(file)
          [loc] ->
            {:redirect, loc}
        end
      %HTTPoison.AsyncChunk{chunk: chunk} ->
        IO.binwrite(file, chunk)
        write_http_to_file(file)
      %HTTPoison.AsyncEnd{} ->
        :ok
    end
  end

  defp get_redirect({"Location", loc}), do: loc
  defp get_redirect({"location", loc}), do: loc
  defp get_redirect(_), do: nil

  def download_repo_zip!(token, repo_xref, ref, path) do
    download_repo_zip_!(
      token,
      "#{config()[:site]}/repositories/#{repo_xref}/zipball/#{ref}",
      path)
  end

  defp download_repo_zip_!(token, url, path) do
    sink = Task.async(fn -> write_http_to_file(path) end)
    HTTPoison.get!(
      url,
      [
        {"Authorization", "token #{token}"},
        {"Accept", @content_type}],
      [stream_to: sink.pid])
    case Task.await(sink) do
      :ok -> :ok
      {:redirect, loc} -> download_repo_zip_!(token, loc, path)
    end
  end

  @token_exp 400

  def get_integration_token!() do
    import Joken
    cfg = config()
    pem = JOSE.JWK.from_pem(cfg[:pem])
    %{
      iat: current_time(),
      exp: current_time() + @token_exp,
      iss: cfg[:iss]}
    |> token()
    |> sign(rs256(pem))
    |> get_compact()
  end

  def get_installation_token!(installation_xref) do
    integration_token = get_integration_token!()
    get_installation_token!(integration_token, installation_xref)
  end

  def get_installation_token!(integration_token, installation_xref) do
    cfg = config()
    %{body: raw, status_code: 201} = HTTPoison.post!(
      "#{cfg[:site]}/app/installations/#{installation_xref}/access_tokens",
      "",
      [
        {"Authorization", "Bearer #{integration_token}"},
        {"Accept", @content_type}])
    Poison.decode!(raw)["token"]
  end
end
