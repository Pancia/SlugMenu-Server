defmodule Slugmenu do
  use Application

  def start(_type, _args) do
    Slugmenu.Supervisor.start_link
  end
end
