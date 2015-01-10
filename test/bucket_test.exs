defmodule Slugmenu.BucketTest do
  use ExUnit.Case, async: true
  alias Slugmenu.Bucket, as: SB

  setup do
    {:ok, bucket} = SB.start_link
    {:ok, bucket: bucket}
  end

  test "stores values by key",
  %{bucket: bucket} do
    assert SB.get(bucket, "milk") == nil

    SB.put(bucket, "cheeseburger", [3, 4])
    assert SB.get(bucket, "cheeseburger") == [3, 4]
  end

  test "delete/2 gets and removes value by key",
  %{bucket: bucket} do
    SB.put(bucket, "milk", 3)
    assert SB.delete(bucket, "milk") == 3
    assert !SB.get(bucket, "milk")
  end

  defp add_to_avg(item, {len, avg}) do
    new_len = len+1
    new_avg = (avg*len/new_len) + item/new_len
    {len+1, new_avg}
  end

  test "update/3 updates and returns a value with a fn",
  %{bucket: bucket} do
    bucket_name = "cheeseburger"

    SB.put(bucket, bucket_name, [2])
    SB.update(bucket, bucket_name, fn val -> [1|val] end)
    assert SB.get(bucket, bucket_name) == [1,2]

    SB.update(bucket, bucket_name, fn [x, y] -> [x+1, y] end)
    assert SB.get(bucket, bucket_name) == [2,2]

    SB.put(bucket, bucket_name, {3, 3.0})
    SB.update(bucket, bucket_name, fn {len, avg} ->
      add_to_avg(5, {len, avg})
    end)
    assert SB.get(bucket, bucket_name) == {4, 3.5}
  end
end
