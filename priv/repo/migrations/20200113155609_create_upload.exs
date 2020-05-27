defmodule Clayton.Repo.Migrations.CreateUpload do
  use Ecto.Migration

  def change do
    create table(:upload) do
      add(:filename, :string)
      add(:size, :integer)
      add(:content_type, :string)
      add(:hash, :string)
      add(:type, :string)

      timestamps()
    end
  end
end
