defmodule GregslistWeb.UserProfileLive.Index do
  use GregslistWeb, :live_view

  alias Gregslist.Accounts

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Gregslist.PubSub, "about_me:updated")
    end

    user = socket.assigns.current_user
    {:ok, assign(socket, user: user, editing_about_me: false)}
  end

  def handle_event("edit_about_me", _, socket) do
    {:noreply, assign(socket, editing_about_me: true)}
  end

  def handle_event("save_about_me", %{"about_me" => about_me}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_about_me(user, %{"about_me" => about_me}) do
      {:ok, updated_user} ->
        Phoenix.PubSub.broadcast(
          Gregslist.PubSub,
          "about_me:updated",
          %{user_id: updated_user.id, about_me: updated_user.about_me}
        )

        {:noreply,
         socket
         |> assign(user: updated_user, editing_about_me: false)
         |> put_flash(:info, "Your About Me has been updated!")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "There was an error updating your About Me.")
         |> assign(editing_about_me: true)}
    end
  end

  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, editing_about_me: false)}
  end

  def handle_info(%{user_id: user_id, about_me: about_me}, socket) do
    if user_id == socket.assigns.user.id do
      {:noreply, assign(socket, user: %{socket.assigns.user | about_me: about_me})}
    else
      {:noreply, socket}
    end
  end
end
