defmodule SynopticonWeb.SessionControllerTest do
  use SynopticonWeb.ConnCase

  setup do
    original_password = Application.get_env(:synopticon, :password)
    Application.put_env(:synopticon, :password, "test-secret")

    on_exit(fn ->
      if is_nil(original_password) do
        Application.delete_env(:synopticon, :password)
      else
        Application.put_env(:synopticon, :password, original_password)
      end
    end)
  end

  test "POST /login accepts configured password", %{conn: conn} do
    conn = post(conn, ~p"/login", password: "test-secret")

    assert redirected_to(conn) == ~p"/"
    assert get_session(conn, :authenticated) == true
  end

  test "POST /login rejects the old hardcoded password", %{conn: conn} do
    conn = post(conn, ~p"/login", password: "synopticon")

    assert redirected_to(conn) == ~p"/"
    refute get_session(conn, :authenticated)
  end
end
