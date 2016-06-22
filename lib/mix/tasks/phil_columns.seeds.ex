defmodule Mix.Tasks.PhilColumns.Seeds do

  use Mix.Task

  import Mix.Ecto
  import Mix.PhilColumns

  @shortdoc "Displays the repository seed status"
  @recursive true

  @moduledoc """
  Displays the up / down seed status for the given repository.
  The repository must be set under `:ecto_repos` in the
  current app configuration or given via the `-r` option.
  By default, seeds are expected at "priv/YOUR_REPO/seeds"
  directory of the current application but it can be configured
  by specifying the `:priv` key under the repository configuration.
  If the repository has not been started yet, one will be
  started outside our application supervision tree and shutdown
  afterwards.
  ## Examples
      mix ecto.seeds
      mix ecto.seeds -r Custom.Repo
  ## Command line options
    * `-r`, `--repo` - the repo to obtain the status for
  """

  @doc false
  def run(args, seeds \\ &PhilColumns.Seeder.seeds/2, puts \\ &IO.puts/1) do
    repos = parse_repo(args)
            |> List.wrap

    result = Enum.map(repos, fn repo ->
      ensure_repo(repo, args)
      ensure_seeds_path(repo)
      {:ok, pid} = ensure_started(repo)

      repo_status = seeds.(repo, seeds_path(repo))

      pid && ensure_stopped(pid)

      """
      Repo: #{inspect repo}
        Status    Migration ID    Migration Name
      --------------------------------------------------
      """ <>
      Enum.map_join(repo_status, "\n", fn({status, number, description}) ->
        status =
          case status do
            :up   -> "up  "
            :down -> "down"
          end

        "  #{status}      #{number}  #{description}"
      end) <> "\n"
    end)

     puts.(Enum.join(result, "\n"))
  end
end
