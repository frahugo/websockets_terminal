defmodule WebsocketsTerminal.ShellServer do
  alias Porcelain.Process, as: Process

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def eval(server, command) do
    GenServer.cast(server, {:eval, command})
  end

  # Private

  def init(:ok) do
    proc = Porcelain.spawn_shell("/bin/bash 2>&1", in: :receive, out: {:send, self})
    WebsocketsTerminal.Endpoint.broadcast! "shell:shell", "stdout", %{data: "-- shell started. Listening."}
    {:ok, proc}
  end

  def handle_cast({:eval, command}, proc) do
    IO.inspect command
    Process.send_input(proc, "#{command}\n")
    {:noreply, proc}
  end

  def handle_info({_, :data, :out, data}, proc) do
    IO.inspect(data)
    WebsocketsTerminal.Endpoint.broadcast! "shell:shell", "stdout", %{data: data}
    {:noreply, proc}
  end
  def handle_info({_, :result, %Porcelain.Result{err: nil, out: _, status: 2}}, proc) do
    WebsocketsTerminal.Endpoint.broadcast! "shell:shell", "stdout", %{data: "-- shell crashed. Restarting..."}
    {:stop, :normal, "bash crashed"}
  end

  def handle_info(noclue, proc) do
    IO.puts "unhandled info"
    IO.inspect noclue
    {:noreply, proc}
  end

  def terminate(reason, socket) do
    IO.inspect reason
  end
end