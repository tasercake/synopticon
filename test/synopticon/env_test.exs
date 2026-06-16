defmodule Synopticon.EnvTest do
  use ExUnit.Case, async: false

  setup do
    original_password_env = System.get_env("SYNOPTICON_PASSWORD")
    original_config = Application.get_env(:synopticon, :password)

    on_exit(fn ->
      restore_env("SYNOPTICON_PASSWORD", original_password_env)

      if is_nil(original_config) do
        Application.delete_env(:synopticon, :password)
      else
        Application.put_env(:synopticon, :password, original_config)
      end
    end)
  end

  test "load_dotenv reads SYNOPTICON_PASSWORD from local .env" do
    dir =
      Path.join(System.tmp_dir!(), "synopticon-env-test-#{System.unique_integer([:positive])}")

    File.mkdir_p!(dir)
    File.write!(Path.join(dir, ".env"), "SYNOPTICON_PASSWORD=from-dotenv\n")

    on_exit(fn -> File.rm_rf!(dir) end)
    System.delete_env("SYNOPTICON_PASSWORD")

    assert :ok = Synopticon.Env.load_dotenv(dir)
    assert System.get_env("SYNOPTICON_PASSWORD") == "from-dotenv"
  end

  test "configure_password raises when SYNOPTICON_PASSWORD is missing" do
    System.delete_env("SYNOPTICON_PASSWORD")

    assert_raise RuntimeError, ~r/SYNOPTICON_PASSWORD is missing/, fn ->
      Synopticon.Env.configure_password!()
    end
  end

  test "configure_password stores env password in app config" do
    System.put_env("SYNOPTICON_PASSWORD", "from-env")

    assert :ok = Synopticon.Env.configure_password!()
    assert Application.fetch_env!(:synopticon, :password) == "from-env"
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
