defmodule UnfinalWeb.PageControllerTest do
  use UnfinalWeb.ConnCase

  test "GET / renders the editor and login form", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ ~s(<article id="readonly-document")
    refute response =~ "password"
    assert response =~ "Login to edit"
  end
end
