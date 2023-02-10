defmodule Mix.Tasks.Ecto.Gen.ViewMigration do
  use Mix.Task, async: :true

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto
  import Mix.EctoSQL

  @impl true
  def run(args) do
    repos = parse_repo(args)

    Enum.map(repos, fn repo ->
      case OptionParser.parse!(args, switches: [migrations_path: :string, sql_path: :string]) do
        {opts, [name]} ->
          ensure_repo(repo, args)

          ts = opts[:timestamp] || timestamp()

          sql_path = opts[:sql_path] || Path.join(source_repo_priv(repo), "sql")
          sql_basename = "#{underscore(name)}_#{ts}.sql"
          sql_file = Path.join(sql_path, sql_basename)
          unless File.dir?(sql_path), do: create_directory(sql_path)

          prev_sql =
            Path.join(sql_path, "#{underscore(name)}_*.sql")
            |> Path.wildcard()
            |> Enum.sort(:desc)
            |> List.first()

          prev_sql_basename = if prev_sql, do: Path.basename(prev_sql)

          create_file(sql_file, sql_template(name: name))

          migration_path =
            opts[:migrations_path] || Path.join(source_repo_priv(repo), "migrations")

          migration_basename = "#{ts}_load_sql_#{underscore(name)}.exs"
          migration_file = Path.join(migration_path, migration_basename)
          unless File.dir?(migration_path), do: create_directory(migration_path)

          assigns = [
            name: name,
            sql_basename: sql_basename,
            prev_sql_basename: prev_sql_basename,
            mod: Module.concat([repo, Migrations, camelize(name)])
          ]

          create_file(migration_file, migration_template(assigns))

          if open?(sql_file) and Mix.shell().yes?("Do you want to run this migration?") do
            Mix.Task.run("ecto.migrate", [
              "-r",
              inspect(repo),
              "--migrations-path",
              migration_path
            ])
          end

          {sql_file, migration_file}

        {_, _} ->
          Mix.raise(
            "expected ecto.gen.view_migration to receive the view file name, " <>
              "got: #{inspect(Enum.join(args, " "))}"
          )
      end
    end)
  end

  defp migration_module do
    case Application.get_env(:ecto_sql, :migration_module, Ecto.Migration) do
      migration_module when is_atom(migration_module) -> migration_module
      other -> Mix.raise("Expected :migration_module to be a module, got: #{inspect(other)}")
    end
  end

  defp app_name do
    Mix.Project.config()[:app]
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  embed_template(:sql, """
  create or replace view <%= @name %> as
  -- insert your view here
  """)

  embed_template(:migration, """
  defmodule <%= inspect @mod %> do
    use <%= inspect migration_module() %>
    def up do
      sql = Path.join(:code.priv_dir(<%= app_name() %>), "repo/sql", <%= inspect @sql_basename %>) |> File.read()
      execute(sql)
    end

    def down do
      sql =<%= if @prev_sql_basename do %> Path.join(:code.priv_dir(<%= app_name() %>), "repo/sql", <%= inspect @prev_sql_basename %>) |> File.read()<% else %> "drop view if exists <%= @name %>"<% end %>
      execute(sql)
    end
  end
  """)
end
