defmodule GregslistWeb.ItemLive.Index do
  use GregslistWeb, :live_view

  alias Gregslist.Galleries
  alias Gregslist.Galleries.Item


  @impl true
def mount(_params, _session, socket) do
  if connected?(socket) do
    Galleries.subscribe()
  end

  {:ok, stream(socket, :items, Galleries.list_items())}
end



  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Item")
    |> assign(:item, Galleries.get_item!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Item")
    |> assign(:item, %Item{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Items")
    |> assign(:item, nil)
  end

  @impl true
  def handle_info({GregslistWeb.ItemLive.FormComponent, {:saved, item}}, socket) do
    {:noreply, stream_insert(socket, :items, item)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = Galleries.get_item!(id)
    {:ok, _} = Galleries.delete_item(item)

    {:noreply, stream_delete(socket, :items, item)}
  end

  @impl true
  def handle_info({item_created, item}, socket) do
  {:noreply, update(socket, :items, fn items -> [item | items] end)}
  end

  @impl true
  def handle_info({item_updated, item}, socket) do
  {:noreply, update(socket, :items, fn items -> [item | items] end)}
  end

  defp fetch_items do
    Galleries.list_items()
    end
end