defmodule Gregslist.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :username, :string
    field :dob, :date
    field :zipcode, :integer
    field :about_me, :string
    has_many :items, Gregslist.Galleries.Item

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :username, :dob, :zipcode])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  def profile_pic_url_changeset(user, attrs) do
    user
    |> cast(attrs, [:profile_pic_url])
    |> validate_required([:profile_pic_url])
    |> validate_format(:profile_pic_url, ~r/^data:image\/\w+;base64,/, message: "Invalid image data")
  end

defp validate_profile_pic_url(changeset) do
  changeset
  |> validate_format(:profile_pic_url, ~r/^https?:\/\/[^\s]+$/, message: "must be a valid URL starting with http or https")
  |> validate_length(:profile_pic_url, max: 255)
end

  def about_me_changeset(user, about_me_params) do
    user
    |> cast(about_me_params, [:about_me])
    |> validate_length(:about_me, max: 100)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp validate_username(changeset, opts) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 1, max: 12)
    |> validate_format(:username, ~r/^\w+$/, message: "can only contain alphanumeric characters and underscores")
    |> maybe_validate_unique_username(opts)
  end

  defp validate_zipcode(changeset, _opts) do
    changeset
    |> validate_required([:zipcode])
    |> validate_length(:zipcode, min: 5, max: 5)
    |> validate_format(:zipcode, ~r/^\d+$/, message: "can only contain digits")
  end

  defp maybe_validate_unique_username(changeset, opts) do
    if Keyword.get(opts, :validate_username, true) do
      changeset
      |> unsafe_validate_unique(:username, Gregslist.Repo)
      |> unique_constraint(:username)
    else
      changeset
    end
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Gregslist.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def username_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:username])
    |> validate_username(opts)
    |> maybe_validate_unique_username(opts)
  end

  def zipcode_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:zipcode])
    |> validate_zipcode(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Pbkdf2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Gregslist.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  def valid_username?(%Gregslist.Accounts.User{hashed_password: hashed_password}, username)
      when is_binary(hashed_password) and byte_size(username) > 0 do
    Pbkdf2.verify_pass(username, hashed_password)
  end

  def valid_username?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  def valid_zipcode?(%Gregslist.Accounts.User{hashed_password: hashed_password}, zipcode)
      when is_binary(hashed_password) and byte_size(zipcode) > 0 do
    Pbkdf2.verify_pass(zipcode, hashed_password)
  end

  def valid_zipcode?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def validate_current_username(changeset, username) do
    changeset = cast(changeset, %{current_username: username}, [:current_username])

    if valid_username?(changeset.data, username) do
      changeset
    else
      add_error(changeset, :current_username, "is not valid")
    end
  end

  def validate_current_zipcode(changeset, zipcode) do
    changeset = cast(changeset, %{current_zipcode: zipcode}, [:current_zipcode])

    if valid_zipcode?(changeset.data, zipcode) do
      changeset
    else
      add_error(changeset, :current_zipcode, "is not valid")
    end
  end
end
