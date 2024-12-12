defmodule GregslistWeb.UserRegistrationLive do
  use GregslistWeb, :live_view

  alias Gregslist.Accounts
  alias Gregslist.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm bg-gray-100 p-10 rounded-lg shadow-md relative">
      <div class="absolute inset-x-0 top-[-40px] flex justify-center">
        <div class="w-20 h-20 bg-indigo-600 text-white rounded-full flex items-center justify-center overflow-hidden border-4 border-gray-100">
          <svg width="30px" height="28px" viewBox="-5 -0.5 25 25" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <title>communication / 9 - communication, account, add, person, profile, user icon</title>
            <g id="Free-Icons" stroke-width="1" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round">
              <g transform="translate(-747.000000, -156.000000)" id="Group" stroke="#FFFFFF" stroke-width="2">
                <g transform="translate(745.000000, 154.000000)" id="Shape">
                  <path d="M12,13 C9.23857625,13 7,10.7614237 7,8 C7,5.23857625 9.23857625,3 12,3 C14.7614237,3 17,5.23857625 17,8 C17,10.7614237 14.7614237,13 12,13 Z M11.0150512,21 C9.04777237,21 6.37608863,21 3,21 C3.79921286,17.89195 6.4614209,16.2328962 10.9866241,16.0228387">
                  </path>
                  <path d="M18.5,14 L18.5,21 M22,17.5 L15,17.5">
                  </path>
                </g>
              </g>
            </g>
          </svg>
        </div>
      </div>

      <h2 class="text-2xl font-bold text-center mb-4 font-sans mt-8">Register</h2>
      <hr class="border-b-2 border-gray-300 my-4" style="height: 2px;">

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
        class="space-y-4"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input
          field={@form[:email]}
          type="email"
          label="Email"
          required
          class="border rounded-md px-4 py-2 w-full focus:ring-indigo-500 focus:border-indigo-500 font-sans"
        />
        <.input
          field={@form[:password]}
          type="password"
          label="Password"
          required
          class="border rounded-md px-4 py-2 w-full focus:ring-indigo-500 focus:border-indigo-500 font-sans"
        />
        <.input
          field={@form[:username]}
          type="text"
          label="Username"
          required
          class="border rounded-md px-4 py-2 w-full focus:ring-indigo-500 focus:border-indigo-500 font-sans"
        />
        <.input
          field={@form[:dob]}
          type="date"
          label="Date of Birth"
          required
          class="border rounded-md px-4 py-2 w-full focus:ring-indigo-500 focus:border-indigo-500 font-sans"
        />
        <.input
          field={@form[:zipcode]}
          type="text"
          label="Zipcode"
          required
          class="border rounded-md px-4 py-2 w-full focus:ring-indigo-500 focus:border-indigo-500 font-sans"
        />

        <div class="text-center">
          <.button
            phx-disable-with="Creating account..."
            class="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded w-full font-sans">
            Create an account
          </.button>
        </div>
      </.simple_form>

      <p class="text-center mt-4 font-sans">
        Already registered? <a href={~p"/users/log_in"} class="text-indigo-600 font-semibold hover:underline">Log in</a>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
