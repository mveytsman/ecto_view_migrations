defmodule Mix.Tasks.Ecto.Gen.ViewMigrationsTest do
  use ExUnit.Case

  import Mix.Tasks.Ecto.Gen.ViewMigration, only: [run: 1]

  @migrations_path Path.join("tmp", "migrations")
  @sql_path Path.join("tmp", "sql")

  defmodule Repo do
    def __adapter__ do
      true
    end

    def config do
      [priv: "tmp", otp_app: :ecto_view_migrations]
    end
  end

  setup do
    File.rm_rf!(@migrations_path)
    File.rm_rf!(@sql_path)
    :ok
  end

  test "generates a new migration and sql file" do
    [{sql_path, migration_path}] = run(["-r", to_string(Repo), "my_view"])
    assert Path.dirname(sql_path) == Path.expand(@sql_path)
    assert Path.basename(sql_path) =~ ~r/^my_view_\d{14}\.sql$/
    assert Path.dirname(migration_path) == Path.expand(@migrations_path)
    assert Path.basename(migration_path) =~ ~r/^\d{14}_load_sql_my_view\.exs$/

    assert File.read!(sql_path) ==
             """
             create or replace view my_view as
             -- insert your view here
             """

    assert File.read!(migration_path) ==
             """
             defmodule Mix.Tasks.Ecto.Gen.ViewMigrationsTest.Repo.Migrations.MyView do
               use Ecto.Migration
               def up do
                 sql = Path.join(:code.priv_dir(ecto_view_migrations), "repo/sql", "#{Path.basename(sql_path)}") |> File.read()
                 execute(sql)
               end

               def down do
                 sql = "drop view if exists my_view"
                 execute(sql)
               end
             end
             """
  end

  test "generates a rollback if called twice with the same view" do
    [{old_sql_path, _migration_path}] = run(["-r", to_string(Repo), "--timestamp", "20230210042233", "my_view"])
    [{new_sql_path, migration_path}] = run(["-r", to_string(Repo),  "--timestamp", "20230210042234", "my_view"])

    assert File.read!(migration_path) ==
             """
             defmodule Mix.Tasks.Ecto.Gen.ViewMigrationsTest.Repo.Migrations.MyView do
               use Ecto.Migration
               def up do
                 sql = Path.join(:code.priv_dir(ecto_view_migrations), "repo/sql", "#{Path.basename(new_sql_path)}") |> File.read()
                 execute(sql)
               end

               def down do
                 sql = Path.join(:code.priv_dir(ecto_view_migrations), "repo/sql", "#{Path.basename(old_sql_path)}") |> File.read()
                 execute(sql)
               end
             end
             """
  end
end
