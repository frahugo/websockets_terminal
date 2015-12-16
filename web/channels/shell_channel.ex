defmodule WebsocketsTerminal.ShellChannel do
  use Phoenix.Channel

  def join("shell:shell", _message, socket) do
    IO.puts "JOIN #{socket.channel}.#{socket.topic}"
    {:ok, socket}
  end
  def join("shell:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("message", %{"body" => body}, socket) do
    IO.puts body
    command = "> #{body}"
    broadcast! socket, "stdout", %{data: command}
    WebsocketsTerminal.ShellServer.eval(:shell, body)
    {:noreply, socket}
  end
end