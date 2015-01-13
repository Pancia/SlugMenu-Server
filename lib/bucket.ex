defmodule Slugmenu.Bucket do
  @doc """
  Starts a new bucket.
  """
  def start_link do
    Agent.start_link(fn -> HashDict.new end)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    Agent.get(bucket, &HashDict.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &HashDict.put(&1, key, value))
  end

  @doc """
  Deletes `key` from `bucket`.
  Returns the current value of `key`, if `key` exists.
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, fn dict ->
      HashDict.pop(dict, key)
    end)
  end

  @doc """
  Updates `key` in `bucket` using f.
  `f` should be a fn from val to val,
  where val is whatever the val of `bucket` is at `key`.
  """
  def update(bucket, key, f) do
    Agent.update(bucket, fn dict ->
      new_val = f.(HashDict.get(dict, key))
      HashDict.put(dict, key, new_val)
    end)
  end

  def put_and_get(bucket, key, value) do
    Agent.update(bucket, fn dict ->
      HashDict.put(dict, key, value)
    end)
    Slugmenu.Bucket.get(bucket, key)
  end
end
