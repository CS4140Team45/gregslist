defmodule GregslistWeb.PageController do
  use GregslistWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def index(conn, _params) do
  render(conn, :index)
  end

  def gregslist(conn, _params) do
  render(conn, :gregslist)
  end

  def photo(conn, _params) do
    render(conn, :photo)
  end

  def categories(conn, _params) do
  render(conn, :categories)
  end

end
