defmodule GregslistWeb.UserSettingsLive do
  use GregslistWeb, :live_view

  alias Gregslist.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Edit your account username, zipcode, email, or password.</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form
          for={@username_form}
          id="username_form"
          phx-change="validate_username"
          phx-submit="update_username"
        >
        <.input
          field={@username_form[:username]}
          type="text"
          label="Edit username"
          required
        />
        <.input
          field={@username_form[:username_confirmation]}
          type="text"
          label="Confirm new username"
        />
         <label id="current_username_for_username" class="label-class">
          Current username: <span><%= @current_username %></span>
        </label>
          <:actions>
            <.button phx-disable-with="Changing...">Change username</.button>
          </:actions>
        </.simple_form>
      </div>

      <div>
        <.simple_form
          for={@zipcode_form}
          id="zipcode_form"
          phx-change="validate_zipcode"
          phx-submit="update_zipcode"
        >
        <.input
          field={@zipcode_form[:zipcode]}
          type="text"
          label="Edit zipcode"
          maxlength="5"
          required
        />
        <.input
          field={@zipcode_form[:zipcode_confirmation]}
          type="text"
          label="Confirm new zipcode"
        />
         <label id="current_zipcode_for_zipcode" class="label-class">
          Current zipcode: <span><%= @current_zipcode %></span>
        </label>
          <:actions>
            <.button phx-disable-with="Changing...">Change zipcode</.button>
          </:actions>
        </.simple_form>
      </div>

      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    username_changeset = Accounts.change_user_username(user)
    zipcode_changeset = Accounts.change_user_zipcode(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_username, user.username)
      |> assign(:current_zipcode, user.zipcode)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:username_form, to_form(username_changeset))
      |> assign(:zipcode_form, to_form(zipcode_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("validate_username", %{"user" => %{"username" => username, "username_confirmation" => username_confirmation} = user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_username(user_params)
      |> Map.put(:action, :validate)

    changeset =
      if username != username_confirmation do
        Ecto.Changeset.add_error(changeset, :username_confirmation, "Username confirmation does not match")
      else
        changeset
      end

    {:noreply, assign(socket, username_form: to_form(changeset))}
  end


  def handle_event("update_username", %{"user" => %{"username" => username, "username_confirmation" => username_confirmation} = user_params}, socket) do
    user = socket.assigns.current_user

    cond do
      username_confirmation == "" || username != username_confirmation ->
        changeset = Accounts.change_user_username(user, user_params)
        changeset = Ecto.Changeset.add_error(changeset, :username_confirmation, "Username confirmation doesn't match")
        {:noreply, assign(socket, username_form: to_form(changeset))}

      true ->
        case Accounts.update_user_username(user, user_params) do
          {:ok, updated_user} ->
            username_form = Accounts.change_user_username(updated_user) |> to_form()

            {:noreply,
             socket
             |> put_flash(:info, "Username updated successfully.")
             |> assign(current_user: updated_user, current_username: updated_user.username, username_form: username_form)}

          {:error, changeset} ->
            {:noreply, assign(socket, username_form: to_form(changeset))}
        end
    end
  end

  def handle_event("validate_zipcode", %{"user" => %{"zipcode" => zipcode, "zipcode_confirmation" => zipcode_confirmation} = user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_zipcode(user_params)
      |> Map.put(:action, :validate)

    changeset =
      if zipcode != zipcode_confirmation do
        Ecto.Changeset.add_error(changeset, :zipcode_confirmation, "Zipcode confirmation does not match")
      else
        changeset
      end

    {:noreply, assign(socket, zipcode_form: to_form(changeset))}
  end


  def handle_event("update_zipcode", %{"user" => %{"zipcode" => zipcode, "zipcode_confirmation" => zipcode_confirmation} = user_params}, socket) do
    user = socket.assigns.current_user

    cond do
      zipcode_confirmation == "" || zipcode != zipcode_confirmation ->
        changeset = Accounts.change_user_zipcode(user, user_params)
        changeset = Ecto.Changeset.add_error(changeset, :zipcode_confirmation, "Zipcode confirmation doesn't match")
        {:noreply, assign(socket, zipcode_form: to_form(changeset))}

      true ->
        case Accounts.update_user_zipcode(user, user_params) do
          {:ok, updated_user} ->
            zipcode_form = Accounts.change_user_zipcode(updated_user) |> to_form()

            {:noreply,
             socket
             |> put_flash(:info, "Zipcode updated successfully.")
             |> assign(current_zipcode: updated_user, current_zipcode: updated_user.zipcode, zipcode_form: zipcode_form)}

          {:error, changeset} ->
            {:noreply, assign(socket, zipcode_form: to_form(changeset))}
        end
    end
  end


  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.update_user_username(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Username updated successfully")
         |> assign(:current_user, user)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end

    case Accounts.update_user_zipcode(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Zipcode updated successfully")
         |> assign(:current_zipcode, user)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end


end
