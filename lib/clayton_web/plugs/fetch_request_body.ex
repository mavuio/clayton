defmodule Clayton.Plugs.FetchRequestBody do
  @moduledoc "Get public IP address of request from x-forwarded-for header"
  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, length: 100_000_000)
    # body |> IO.inspect(label: "Clayton READBODY")
    conn |> Plug.Conn.put_private(:raw_body, body)
  end

  def read_cached_body(conn) do
    conn.private[:raw_body]
  end
end
