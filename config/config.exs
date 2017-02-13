# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :devdocs, DevDocs,
  self_repo: System.get_env("DEVDOCS_SELF_REPO")

config :devdocs, DevDocs.GitHub,
  iss: String.to_integer(System.get_env("DEVDOCS_GITHUB_ISS")),
  pem: Base.decode64!(System.get_env("DEVDOCS_GITHUB_PEM"))
