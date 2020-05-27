defmodule Clayton.Upload do
  use Ecto.Schema
  import Ecto.Changeset
  alias Clayton.Upload

  schema "upload" do
    field :content_type, :string
    field :filename, :string
    field :hash, :string
    field :size, :integer
    field :type, :string
    has_many(:uploads, Upload)

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:filename, :size, :content_type, :hash, :type])
    # added validations
    |> validate_required([:filename, :size, :content_type, :hash, :type])
    # doesn't allow empty files
    |> validate_number(:size, greater_than: 0)
    |> validate_length(:hash, is: 64)
  end

  def sha256(chunks_enum) do
    chunks_enum
    |> Enum.reduce(
      :crypto.hash_init(:sha256),
      &:crypto.hash_update(&2, &1)
    )
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end

  def upload_directory do
    Application.get_env(:clayton, :uploads_directory)
  end

  def local_path(%{id: id, type: type, filename: filename}) do
    local_path(id, type, filename)
  end

  def local_path(id, type, filename) do
    [upload_directory(), "#{type}-#{id}-#{filename}"]
    |> Path.join()
  end
end
