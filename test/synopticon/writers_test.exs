defmodule Synopticon.WritersTest do
  use ExUnit.Case, async: true

  alias Synopticon.Writers

  test "loads normalized writer emails from file" do
    path =
      temp_file("writers", """

      # friend@example.com
      // other@example.com
        Writer@Example.COM  
      second@example.com
      """)

    assert Writers.emails(path) == MapSet.new(["writer@example.com", "second@example.com"])
  end

  test "missing file means no configured writers" do
    refute Writers.authorized?(
             Path.join(System.tmp_dir!(), "missing-writers.txt"),
             "writer@example.com"
           )
  end

  test "authorization is case insensitive and rejects blank email" do
    path = temp_file("writers", "writer@example.com\n")

    assert Writers.authorized?(path, "WRITER@example.COM")
    refute Writers.authorized?(path, "")
    refute Writers.authorized?(path, nil)
  end

  defp temp_file(name, content) do
    path =
      Path.join(System.tmp_dir!(), "synopticon-#{name}-#{System.unique_integer([:positive])}.txt")

    File.write!(path, content)
    path
  end
end
