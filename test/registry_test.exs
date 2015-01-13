defmodule Slugmenu.RegistryTest do
  use ExUnit.Case, async: true
  alias Slugmenu.Bucket, as: SB
  alias Slugmenu.Registry, as: SR
  alias Slugmenu.Bucket.Supervisor, as: SBS

  defmodule Forwarder do
    use GenEvent

    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end

  setup do
    {:ok, sup}      = SBS.start_link
    {:ok, manager}  = GenEvent.start_link
    {:ok, registry} = SR.start_link(manager, sup)

    GenEvent.add_mon_handler(manager, Forwarder, self())
    {:ok, registry: registry}
  end

  test "registry spawns buckets",
  %{registry: registry} do
    reg_name = "shopping"
    assert SR.lookup(registry, reg_name) == :error

    SR.create(registry, "shopping")
    assert {:ok, bucket} = SR.lookup(registry, reg_name)

    SB.put(bucket, "milk", 1)
    assert SB.get(bucket, "milk") == 1
  end

  test "registry removes buckets on exit",
  %{registry: registry} do
    reg_name = "iremovebucketsonexit"
    SR.create(registry, reg_name)
    {:ok, bucket} = SR.lookup(registry, reg_name)
    Agent.stop(bucket)
    assert SR.lookup(registry, reg_name) == :error
  end

  test "registry sends events on create and crash",
  %{registry: registry} do
    reg_name = "ibroadcastevents"
    SR.create(registry, reg_name)
    {:ok, bucket} = SR.lookup(registry, reg_name)
    assert_receive {:create, reg_name, ^bucket}

    Agent.stop(bucket)
    assert_receive {:exit, reg_name, ^bucket}
  end

  test "registry removes bucket on crash",
  %{registry: registry} do
    reg_name = "iremovemeoncrash"
    SR.create(registry, reg_name)
    {:ok, bucket} = SR.lookup(registry, reg_name)

    # Kill the bucket and wait for the notification
    Process.exit(bucket, :shutdown)
    assert_receive {:exit, reg_name, ^bucket}
    assert SR.lookup(registry, reg_name) == :error
  end
end
