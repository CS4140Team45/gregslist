defmodule GregslistWeb.ItemController do
  use GregslistWeb, :controller
  alias Gregslist.Galleries
  alias Gregslist.Galleries.Item
  alias Gregslist.Repo
  def index(conn, _params) do
    current_user = conn.assigns.current_user
    items =
      Repo.all(Gregslist.Galleries.Item)
      |> Enum.filter(fn item -> item.user_id == current_user.id end)
      |> Repo.preload(:user)
      |> Repo.preload(:images)

    render(conn, "index.html", items: items, current_user: current_user)
  end


  def new(conn, _params) do
    changeset = Galleries.change_item(%Item{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"item" => item_params}) do
    user_id = conn.assigns.current_user.id
    item_params = Map.put(item_params, "user_id", user_id)

    case Galleries.create_item(item_params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "item created successfully.")
        |> redirect(to: "/items")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def detail(conn, %{"id" => id}) do
    item = Repo.get!(Item, id) |> Repo.preload(:user)

    render(conn, "detail.html", item: item)
  end

  def handle_event("div_clicked", %{"id" => item_id}, conn) do
   IO.puts("Div was clicked! Item ID: #{item_id}")

    {:noreply, redirect(conn, to: ~p"/items/#{item_id}/detail")}
  end

  def show(conn, %{"id" => id}) do
    item =
    Repo.get!(Gregslist.Galleries.Item, id)
    |> Repo.preload(:user)

  render(conn, "show.html", item: item)
  end

  def edit(conn, %{"id" => id}) do
    item = Galleries.get_item!(id)
    changeset = Galleries.change_item(item)
    render(conn, :edit, item: item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    item = Galleries.get_item!(id)

    case Galleries.update_item(item, item_params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "item updated successfully.")
        |> redirect(to: ~p"/items/#{item}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, item: item, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Galleries.get_item!(id)
    {:ok, _item} = Galleries.delete_item(item)

    conn
    |> put_flash(:info, "item deleted successfully.")
    |> redirect(to: ~p"/items")
  end
end
