defmodule SynopticonWeb.SessionController do
  use SynopticonWeb, :controller

  def create(conn, %{"password" => password}) do
    configured_password = Application.fetch_env!(:synopticon, :password)

    if byte_size(password) == byte_size(configured_password) and
         Plug.Crypto.secure_compare(password, configured_password) do
      authenticate(conn)
    else
      reject(conn)
    end
  end

  def create(conn, _params), do: reject(conn)

  defp authenticate(conn) do
    conn
    |> put_session(:authenticated, true)
    |> delete_session(:password_error)
    |> redirect(to: ~p"/")
  end

  defp reject(conn) do
    conn
    |> put_session(:password_error, true)
    |> redirect(to: ~p"/")
  end
end
