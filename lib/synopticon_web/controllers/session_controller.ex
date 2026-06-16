defmodule SynopticonWeb.SessionController do
  use SynopticonWeb, :controller

  @dev_fake_user %{"id" => "dev-user-1234", "email" => "dev@example.com"}

  def login(conn, _params) do
    case Application.fetch_env!(:synopticon, :login_mode) do
      :dev_fake ->
        authenticate(conn, @dev_fake_user)

      :exe_headers ->
        case exe_user_from_headers(conn) do
          {:ok, user} -> authenticate(conn, user)
          :error -> redirect(conn, to: exe_login_path(conn))
        end
    end
  end

  defp exe_user_from_headers(conn) do
    with [id] when id != "" <- get_req_header(conn, "x-exedev-userid"),
         [email] when email != "" <- get_req_header(conn, "x-exedev-email") do
      {:ok, %{"id" => id, "email" => email}}
    else
      _ -> :error
    end
  end

  defp authenticate(conn, user) do
    conn
    |> put_session(:authenticated, true)
    |> put_session(:exe_user, user)
    |> redirect(to: ~p"/")
  end

  defp exe_login_path(_conn), do: "/__exe.dev/login?redirect=/login"
end
