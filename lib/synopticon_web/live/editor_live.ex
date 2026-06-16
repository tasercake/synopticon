defmodule SynopticonWeb.EditorLive do
  use SynopticonWeb, :live_view

  alias Synopticon.ContentStore
  alias Synopticon.Writers

  @impl true
  def mount(params, session, socket) do
    path = document_path(params)

    if connected?(socket),
      do: Phoenix.PubSub.subscribe(Synopticon.PubSub, ContentStore.topic(path))

    socket =
      assign(socket,
        path: path,
        content: ContentStore.get(path),
        authenticated: Map.get(session, "authenticated", false),
        exe_user: Map.get(session, "exe_user"),
        writer?: writer?(session)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "save",
        %{"content" => content},
        %{assigns: %{writer?: true, path: path}} = socket
      ) do
    ContentStore.set(path, content)
    {:noreply, assign(socket, :content, content)}
  end

  def handle_event("save", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:content_updated, path, content}, %{assigns: %{path: path}} = socket) do
    {:noreply, assign(socket, :content, content)}
  end

  defp document_path(%{"path" => parts}), do: "/" <> Enum.join(parts, "/")
  defp document_path(_params), do: "/"

  defp writer?(%{"authenticated" => true, "exe_user" => %{"email" => email}}),
    do: Writers.authorized?(email)

  defp writer?(_session), do: false

  @impl true
  def render(assigns) do
    ~H"""
    <div style="min-height: 100vh; display: flex; flex-direction: column; margin: 0;">
      <.form
        :if={@writer?}
        for={%{}}
        as={:editor}
        id="editor-form"
        phx-change="save"
        style="flex: 1; display: flex; margin: 0;"
      >
        <textarea name="content" style="flex: 1; width: 100%; resize: none; border: 0; padding: 8px;"><%= @content %></textarea>
      </.form>

      <textarea
        :if={!@writer?}
        name="content"
        readonly="readonly"
        style="flex: 1; width: 100%; resize: none; border: 0; padding: 8px;"
      ><%= @content %></textarea>

      <div id="login-bar" style="display: flex; gap: 4px; padding: 4px;">
        <a :if={!@authenticated} href="/login">Login with exe</a>
        <span :if={@authenticated and @writer?}>authenticated as {@exe_user["email"]}</span>
        <span :if={@authenticated and !@writer?}>authenticated as {@exe_user["email"]} (read only)</span>
      </div>
    </div>
    """
  end
end
