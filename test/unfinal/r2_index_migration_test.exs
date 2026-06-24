defmodule Unfinal.R2IndexMigrationTest do
  use ExUnit.Case, async: false

  alias Unfinal.FakeObjectStore
  alias Unfinal.R2IndexMigration

  setup do
    Application.put_env(:unfinal, :object_store_adapter, FakeObjectStore)
    FakeObjectStore.clear()
    :ok
  end

  test "migrates namespace rows and preserves existing index rows" do
    old_path = temp_file("old-namespaces", "alice\talice@example.com\n")
    :ok = FakeObjectStore.put_object("indexes/namespaces.txt", "bob\tbob@example.com\n")

    assert {:ok, %{namespaces_written: 2, pages_written: 0, dry_run?: false}} =
             R2IndexMigration.run(namespaces_path: old_path)

    assert {:ok, "alice\talice@example.com\nbob\tbob@example.com\n"} =
             FakeObjectStore.get_object("indexes/namespaces.txt")
  end

  test "upserts manifest rows as per-namespace page indexes" do
    manifest_path = temp_file("manifest", "alice\t/one\nalice\t/folder/two\n")

    assert {:ok, %{pages_written: 2}} = R2IndexMigration.run(manifest_path: manifest_path)

    assert {:ok, content} = FakeObjectStore.get_object("indexes/namespaces/alice.ndjson")
    assert String.contains?(content, ~s("path":"/one"))
    assert String.contains?(content, ~s("path":"/folder/two"))
  end

  test "dry run does not write object indexes" do
    old_path = temp_file("old-namespaces", "alice\talice@example.com\n")
    manifest_path = temp_file("manifest", "alice\t/one\n")

    assert {:ok, %{namespaces_written: 1, pages_written: 1, dry_run?: true}} =
             R2IndexMigration.run(
               namespaces_path: old_path,
               manifest_path: manifest_path,
               dry_run?: true
             )

    assert {:error, :not_found} = FakeObjectStore.get_object("indexes/namespaces.txt")
    assert {:error, :not_found} = FakeObjectStore.get_object("indexes/namespaces/alice.ndjson")
  end

  defp temp_file(name, content) do
    path = Path.join(System.tmp_dir!(), "#{name}-#{System.unique_integer([:positive])}.tsv")
    File.write!(path, content)
    path
  end
end
