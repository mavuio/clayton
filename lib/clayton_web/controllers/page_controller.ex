defmodule ClaytonWeb.PageController do
  use ClaytonWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def success(conn,_params) do
    conn |> html("URL is ok")
  end

  def store(conn, params) do
    conn |>IO.inspect(label: "PUT mwuits-debug 2020-05-27_21:55 ")
    render(conn, "index.html")
  end
end
