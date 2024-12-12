defmodule Gregslist.Messages do
  import Ecto.Query, warn: false
  alias Gregslist.Repo
  alias Gregslist.Messages.Message

  def get_messages(sender_id, receiver_id) do
    Repo.all(
      from m in Message,
      where:
        (m.sender_id == ^sender_id and m.receiver_id == ^receiver_id) or
          (m.sender_id == ^receiver_id and m.receiver_id == ^sender_id),
      order_by: [asc: m.timestamp]
    )
  end
  def load_messages(sender_id, receiver_id) do
    from(m in Message,
      where: (m.sender_id == ^sender_id and m.receiver_id == ^receiver_id) or
             (m.sender_id == ^receiver_id and m.receiver_id == ^sender_id),
      order_by: [asc: m.timestamp],
      preload: [:sender, :receiver]  # Preload sender and receiver associations
    )
    |> Repo.all()
  end


  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  #Sorta borrowed and changed one of the functions from galleries.ex for this
  def list_messages(sort_order \\ "asc") do
    from(m in Message, order_by: [{^String.to_atom(sort_order), :receiver_id}])
    |> Repo.all()
    |> Repo.preload([:messages, :user])
  end

  # Also learned more about flat_map here: https://elixirforum.com/t/different-behavior-between-list-flatten-and-enum-stream-flat-map/52826
  # And Enum.uniq: https://hexdocs.pm/elixir/1.17.2/Enum.html#uniq/1
  def fetch_open_chats(user_id) do
    from(m in Message,
      where: m.sender_id == ^user_id or m.receiver_id == ^user_id,
      select: [m.sender_id, m.receiver_id]
    )
    |> Repo.all()
    |> Enum.flat_map(fn [sender_id, receiver_id] ->
      if sender_id == user_id, do: [receiver_id], else: [sender_id]
    end)
    |> Enum.uniq()
  end

end
