defmodule ClaytonWeb.PageController do
  use ClaytonWeb, :controller

  alias Clayton.Upload
  alias Clayton.Repo

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def success(conn, _params) do
    conn |> html("URL is ok")
  end

  def get_random_code(length) do
    Enum.shuffle(~w( A B C D E G H J K L M N P R S T U V X))
    |> Enum.join("")
    |> String.slice(1..length)
  end

  def store(conn, params) do
    params |> IO.inspect(label: "file-uploaded #{inspect(conn.req_headers)}")

    # "aa" |> IO.inspect(label: "mwuits-debug 2020-05-27_23:20 bidy: #{conn.private[:raw_body]}")

    x_callid = conn |> get_req_header("x-callid") |> hd()

    code = "#{x_callid}" |> String.slice(0, 5)
    random_code = get_random_code(2)

    time =
      DateTime.utc_now()
      |> to_string()
      |> String.split(".")
      |> hd()
      |> String.replace(" ", "_")
      |> String.replace(":", "-")

    file = [Upload.upload_directory(), "#{time}_#{code}_#{random_code}.ogg"] |> Path.join()

    File.write(file, conn.private[:raw_body])

    split_file(file)
    conn |> html("OK")
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

  def split_file(name) do
    System.cmd("ffmpeg", [
      "-i",
      "#{name}",
      "-map_channel",
      "0.0.0",
      name |> String.replace_trailing(".ogg", ".local.wav"),
      "-map_channel",
      "0.0.1",
      name |> String.replace_trailing(".ogg", ".partner.wav")
    ])
  end
end
