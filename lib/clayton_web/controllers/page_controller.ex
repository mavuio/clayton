defmodule ClaytonWeb.PageController do
  use ClaytonWeb, :controller

  alias  Clayton.Upload
  alias  Clayton.Repo
  def index(conn, _params) do
    render(conn, "index.html")
  end

  def success(conn,_params) do
    conn |> html("URL is ok")
  end

  def store(conn, %{"upload" => %Plug.Upload{} = upload, "type" => type}) do
    conn|>IO.inspect(label: "mwuits-debug 2020-05-27_22:47 ")
    case create_upload_from_plug_upload(type, upload) do
      {:ok, upload} ->
         conn  |> html("ok #{inspect (upload)}")
        # redirect(conn, to: Routes.upload_path(conn, :index, type))

      {:error, reason} ->
        conn  |> html( "error upload file: #{inspect(reason)}")
        # render(conn, "new.html")
    end
  end

  def create_upload_from_plug_upload(type, %Plug.Upload{
    filename: filename,
    path: tmp_path,
    content_type: content_type
  })
  when is_binary(type) do
hash =
  File.stream!(tmp_path, [], 2048)
  |> Upload.sha256()

Repo.transaction(fn ->
  with {:ok, %File.Stat{size: size}} <- File.stat(tmp_path),
       {:ok, upload} <-
         %Upload{}
         |> Upload.changeset(%{
           filename: filename,
           content_type: content_type,
           hash: hash,
           size: size,
           type: type
         })
         |> Repo.insert(),
       :ok <-
         File.cp(
           tmp_path,
           Upload.local_path(upload.id, upload.type, filename)
           |> IO.inspect(label: "mwuits-debug 2020-01-13_17:41 ")
         ) do
    {:ok, upload}
  else
    {:error, reason} -> Repo.rollback(reason)
  end
end)

# upload creation logic
end

end
