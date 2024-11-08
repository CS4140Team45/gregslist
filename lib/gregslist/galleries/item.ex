defmodule Gregslist.Galleries.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :user_name, :string
    field :location, :string
    field :categories
    field :desc, :string
    field :item_name, :string
    field :price, :float
    field :art_image, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    #|> cast(attrs, [:item_name, :category, :desc, :price, :location, :art_image])
    |> cast(attrs, [:item_name, :categories, :desc, :price, :location])
    |> validate_required([:item_name, :categories, :desc, :price, :location])
    |> validate_length(:desc, min: 2, max: 250)
  end
end