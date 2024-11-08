defmodule GregslistWeb.PageController do
  use GregslistWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def index(conn, _params) do
  render(conn, :index)
  end

  def gregslist(conn, _params) do
  render(conn, :gregslist)
  end

  def categories(conn, _params) do
  render(conn, "categories.html")
  end

end
