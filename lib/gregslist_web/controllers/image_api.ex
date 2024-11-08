defmodule GregslistWeb.ImageApi do
  use GregslistWeb, :controller
  alias Gregslist.Image

def add_image(conn, %{"image" => image_params}) do
  IO.inspect(image_params, label: "Image Params")
  case Image.insert(image_params) do
    {:ok, image} ->
      conn
      |> put_status(:created)
      |> json(%{image: image})

    {:error, changeset} ->
      errors = Enum.reduce(changeset.errors, %{}, fn {field, {message, _}}, acc ->
        Map.put(acc, to_string(field), message)
      end)

      conn
      |> put_status(:unprocessable_entity)
      |> json(%{errors: errors})
  end
end
end
