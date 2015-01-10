defmodule Slugmenu.BucketTest do
  use ExUnit.Case, async: true
  alias Slugmenu.Bucket, as: SB

  setup do
    {:ok, bucket} = SB.start_link
    {:ok, bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert SB.get(bucket, "milk") == nil

    SB.put(bucket, "milk", 3)
    assert SB.get(bucket, "milk") == 3
  end

  test "delete gets and removes value by key", %{bucket: bucket} do
    SB.put(bucket, "milk", 3)
    assert SB.delete(bucket, "milk") == 3
    assert !SB.get(bucket, "milk")
  end
end
