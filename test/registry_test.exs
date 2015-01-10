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

  test "registry spawns buckets", %{registry: registry} do
    assert SR.lookup(registry, "shopping") == :error

    SR.create(registry, "shopping")
    assert {:ok, bucket} = SR.lookup(registry, "shopping")

    SB.put(bucket, "milk", 1)
    assert SB.get(bucket, "milk") == 1
  end

  test "registry removes buckets on exit", %{registry: registry} do
    SR.create(registry, "shopping")
    {:ok, bucket} = SR.lookup(registry, "shopping")
    Agent.stop(bucket)
    assert SR.lookup(registry, "shopping") == :error
  end

  test "registry sends events on create and crash", %{registry: registry} do
    SR.create(registry, "shopping")
    {:ok, bucket} = SR.lookup(registry, "shopping")
    assert_receive {:create, "shopping", ^bucket}

    Agent.stop(bucket)
    assert_receive {:exit, "shopping", ^bucket}
  end

  test "registry removes bucket on crash", %{registry: registry} do
    SR.create(registry, "shopping")
    {:ok, bucket} = SR.lookup(registry, "shopping")

    # Kill the bucket and wait for the notification
    Process.exit(bucket, :shutdown)
    assert_receive {:exit, "shopping", ^bucket}
    assert SR.lookup(registry, "shopping") == :error
  end

end
