defmodule Slugmenu.Server do
  alias Slugmenu.Server.Command, as: SSC

  def accept(port) do
    # `active: false` -> block on `:gen_tcp.recv/2` until data is available
    {:ok, socket} = :gen_tcp.listen(port,
    [:binary, packet: :line, active: false])
    IO.puts "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Task.Supervisor.start_child(Slugmenu.Server.TaskSupervisor, fn ->
      serve(client) end)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    import Pipe

    msg = pipe_matching x, {:ok, x},
      read_line(socket)
      |> SSC.parse |> SSC.run()

    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, msg) do
    :gen_tcp.send(socket, format_msg(msg))
  end

  defp format_msg({:ok, text}),                do: text
  defp format_msg({:error, :unknown_command}), do: "UNKNOWN COMMAND\n"
  defp format_msg({:error, :not_found}),       do: "NOT FOUND \n"
  defp format_msg({:error, _}),                do: "ERROR\n"
end
