defmodule Mix.Tasks.Unfinal.MigrateR2Indexes do
  @moduledoc """
  Migrates old local namespace ownership and known page paths into R2 indexes.

  This task does not scan R2 document keys for page paths. Existing document object
  keys are hashed (`documents/<sha256>.txt`), so a manifest is required for page indexes.

  Manifest format is TSV, one page per line:

      namespace<TAB>/relative/path

  Example:

      alice\t/first-note
      alice\t/folder/second-note

  Run on exe.dev VM:

      MIX_ENV=prod mix unfinal.migrate_r2_indexes --dry-run --manifest /tmp/unfinal-pages.tsv
      MIX_ENV=prod mix unfinal.migrate_r2_indexes --manifest /tmp/unfinal-pages.tsv

  Optional flags:

      --namespaces /path/to/namespaces.txt  # default: $UNFINAL_DATA_DIR/namespaces.txt or ./.data/namespaces.txt
      --manifest /path/to/pages.tsv
      --dry-run
  """

  use Mix.Task

  @shortdoc "Migrates old namespace TSV and page manifest into R2 indexes"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [namespaces: :string, manifest: :string, dry_run: :boolean],
        aliases: [n: :namespaces, m: :manifest]
      )

    if invalid != [] do
      Mix.raise("invalid option(s): #{inspect(invalid)}")
    end

    migration_opts =
      []
      |> put_if_present(:namespaces_path, opts[:namespaces])
      |> put_if_present(:manifest_path, opts[:manifest])
      |> Keyword.put(:dry_run?, Keyword.get(opts, :dry_run, false))

    case Unfinal.R2IndexMigration.run(migration_opts) do
      {:ok, summary} ->
        Mix.shell().info("R2 index migration complete")
        Mix.shell().info("dry_run?: #{summary.dry_run?}")
        Mix.shell().info("namespace rows after merge: #{summary.namespaces_written}")
        Mix.shell().info("page manifest rows processed: #{summary.pages_written}")

        if is_nil(opts[:manifest]) do
          Mix.shell().info(
            "No page manifest supplied; per-namespace page indexes were not changed."
          )
        end

      {:error, reason} ->
        Mix.raise("R2 index migration failed: #{inspect(reason)}")
    end
  end

  defp put_if_present(opts, _key, nil), do: opts
  defp put_if_present(opts, key, value), do: Keyword.put(opts, key, value)
end
