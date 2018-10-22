defmodule DevDocs do
  @moduledoc """
  The task that builds a dev doc.
  """

  @self_repo Application.get_env(:devdocs, DevDocs)[:self_repo]

  use Application

  def start(_type, _args) do
    integration_token = DevDocs.GitHub.get_integration_token!()
    integration_token
    |> DevDocs.GitHub.get_installations!()
    |> Enum.map(&document_installation(integration_token, &1))
    document_all()
    Task.start_link fn -> Application.stop(:devdocs) end
  end

  def document_installation(integration_token, installation_xref) do
    installation_token = integration_token
    |> DevDocs.GitHub.get_installation_token!(installation_xref)
    installation_token
    |> DevDocs.GitHub.get_installation_repos!()
    |> Enum.map(&document_repo(installation_token, &1))
    |> Enum.filter(&(not is_nil(&1)))
  end

  def document_repo(installation_token, %{"full_name" => @self_repo}) do
    IO.puts "Setting up Git"
    {_, 0} = System.cmd("git", ["init"], cd: "_docsubmit")
    {_, 0} = System.cmd("git", ["checkout", "-b", "gh-pages"], cd: "_docsubmit")
    origin = "https://x-access-token:#{installation_token}@github.com/#{@self_repo}.git"
    {_, 0} = System.cmd("git", ["remote", "add", "origin", origin], cd: "_docsubmit")
    nil
  end

  def document_repo(installation_token, repo) do
    IO.puts repo["name"]
    fname = "_docbuild/#{repo["name"]}"
    zname = "_docbuild/#{repo["name"]}.zip"
    DevDocs.GitHub.download_repo_zip!(
      installation_token,
      repo["id"],
      repo["default_branch"],
      zname)
    {:ok, _} = :zip.unzip(String.to_charlist(zname), [cwd: String.to_charlist(fname)])
    rname = "#{fname}/#{single_dir(File.ls!(fname))}"
    dname = "#{rname}/doc"
    {_, 0} = System.cmd("mix", ["deps.get"], cd: rname)
    {_, 0} = System.cmd("mix", ["docs"], cd: rname)
    :ok = File.rename(dname, "_docsubmit/#{repo["name"]}")
    repo["name"]
  end

  def document_all(list) do
    {:ok, index_html} = File.open("_docsubmit/index.html", [:write])
    :ok = IO.write(index_html, "<!DOCTYPE html><meta name=viewport content=width=device-width><ul>")
    document_add_git(list, index_html)
    {:ok, nojekyll} = File.open("_docsubmit/.nojekyll", [:write])
    :ok = IO.write(nojekyll, "\n")
  end

  def document_add_git(name, index_html) when is_binary name do
    {_, 0} = System.cmd("git", ["add", name], cd: "_docsubmit")
    :ok = IO.write(index_html, ["<li><a href='", name, "'>", name, "</a>"])
  end
  def document_add_git(list, index_html) when is_list list do
    Enum.each(list, &document_add_git(&1, index_html))
  end

  def single_dir(["." | rest]) do
    single_dir(rest)
  end
  def single_dir([".." | rest]) do
    single_dir(rest)
  end
  def single_dir([dir]) do
    dir
  end
end
