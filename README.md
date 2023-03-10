# Ecto ViewMigrations

Database views are a powerful tool, but it can be hard to fit them into your Ecto migrations.

This tool provides a generator to create migrations for views that are written directly in SQL.

## Usage

```bash
mix ecto.gen.view_migration my_view_name
```

This will generate two files:
- `priv/repo/migrations/[TIMESTAMP]_load_sql_my_view_name.exs`
- `priv/repo/sql/my_view_name_[TIMESTAMP].sql`

You write your view in the `.sql` file and the autogenerated migration will handle loading it and dropping it on revert.

If you are changing an existing view, the migration generator will detect this and load the old version on revert accordingly.
## Future Work

Note that, at least in Postgres, `create or replace view` lets you modify the query not the columns. We will want to let the user specify `alter view` or some other mechanism if they need to add or delete columns. Currently, you'd have to do this by hand in the migration.
## Installation

The package can be installed by adding `ecto_view_migrations` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_view_migrations, "~> 0.1.0"}
  ]
end
```

Documentation can be at <https://hexdocs.pm/ecto_view_migrations>.

