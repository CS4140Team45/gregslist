defmodule GregslistWeb.ItemLive.Myitems do
  use GregslistWeb, :live_view
  alias Gregslist.Galleries
  alias Gregslist.Repo
  @impl true

  def mount(_params, _session, socket) do
    IO.inspect(socket.assigns, label: "Socket assigns at mount start")
    user = socket.assigns[:current_user]
    if user do
      IO.inspect(user, label: "Current user")
      items =
        Galleries.list_items()
        |> Repo.preload(:images)
        |> Enum.filter(fn item -> item.user_id == user.id end)
        IO.inspect(items, label: "Filtered items")
      {:ok, assign(socket, user: user, items: items)}
    else
      IO.puts("No current_user found in socket.assigns")
      {:ok, assign(socket, user: nil, items: [])}
    end
  end

@impl true
  def handle_event("div_clicked", %{"id" => item_id}, socket) do
    IO.puts("Div was clicked! Item ID: #{item_id}")
    {:noreply, push_navigate(socket, to: ~p"/items/#{item_id}/detail")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <header class="mb-4">
      <h2 class="text-xl font-medium text-gray-400 flex items-center ml-2">
        <a href="/gregslist">
          <span class="mr-1">←</span>
          Back to Categories
        </a>
      </h2>
    </header>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <%= if length(@items) == 0 do %>
        <div class="text-center text-gray-500">
          <p>You have no items listed yet.</p>
        </div>
      <% else %>
        <%= for item <- @items do %>
          <div class="bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow"
            style="cursor: pointer;"phx-click={JS.push("div_clicked", value: %{id: item.id})}>
            <%= if item.images !=nil && length(item.images) > 0 do %>
              <img src={hd(item.images).dataUrl} />
            <% end %>
          <h2 class="text-2xl font-semibold text-gray-800 mb-2"><%= item.item_name %></h2>
        <p class="text-gray-700 mb-4"><%= item.desc %></p>
        <p class="text-indigo-700 font-semibold mb-2"><strong>Price:</strong> $<%= item.price %></p>
        <p class="text-gray-700 mb-4"><strong>Location:</strong> <%= item.location %></p>
        </div>
        <% end %>
    <% end %>
    </div>
    """
  end
end
