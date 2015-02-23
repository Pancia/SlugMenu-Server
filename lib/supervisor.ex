defmodule Slugmenu.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @manager_name Slugmenu.EventManager
  @bucket_sup_name Slugmenu.Bucket.Supervisor
  @registry_name Slugmenu.Registry
  @server_name Slugmenu.Server
  @server_sup_name Slugmenu.Server.TaskSupervisor

  def init(:ok) do
    {port, _} = Integer.parse(Mix.Project.config()[:port])
    children = [
      worker(GenEvent, [[name: @manager_name]]),
      worker(Slugmenu.Bucket.Supervisor, [[name: @bucket_sup_name]]),
      worker(Slugmenu.Registry, [@manager_name, @bucket_sup_name, [name: @registry_name]]),
      supervisor(Task.Supervisor, [[name: @server_sup_name]]),
      worker(Task, [@server_name, :accept, [port]]),
      worker(Slugmenu.RestServer, [])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
