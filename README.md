# [Developer documentation](https://bors-ng.github.io/devdocs/)

This repo will generate ExDoc documentation on Travis CI and publish it to a GitHub page. This is great for generating dev docs for apps that aren't published to Hex (because they're not really usable as libraries).

If you want to use this for your Elixir project:

  * Fork this repo.
  * Make a GitHub integration with access to the repos you want to build plus the fork's repo.
    It will also need write access, to push the `gh_pages` branch when it's done.
  * Enable Travis on the fork's repo and set the env variables listed in `config/config.exs`.
  * Turn on a Travis cronjob for the fork's repo.
  * Tweak the fork's readme (optional).
