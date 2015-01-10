defmodule Slugmenu.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @manager_name Slugmenu.EventManager
  @bucket_sup_name Slugmenu.Bucket.Supervisor
  @registry_name Slugmenu.Registry

  def init(:ok) do
    children = [
      worker(GenEvent, [[name: @manager_name]]),
      worker(Slugmenu.Bucket.Supervisor, [[name: @bucket_sup_name]]),
      worker(Slugmenu.Registry, [@manager_name, @bucket_sup_name, [name: @registry_name]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
