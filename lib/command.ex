defmodule Slugmenu.Server.Command do
  alias Slugmenu.Registry, as: SR
  alias Slugmenu.Bucket,   as: SB
  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples

  iex> Slugmenu.Server.Command.parse "CREATE shopping\n"
  {:ok, {:create, "shopping"}}

  iex> Slugmenu.Server.Command.parse "CREATE  shopping  \n"
  {:ok, {:create, "shopping"}}

  iex> Slugmenu.Server.Command.parse "PUT shopping milk 1\n"
  {:ok, {:put, "shopping", "milk", "1"}}

  iex> Slugmenu.Server.Command.parse "GET shopping milk\n"
  {:ok, {:get, "shopping", "milk"}}

  iex> Slugmenu.Server.Command.parse "DELETE shopping eggs\n"
  {:ok, {:delete, "shopping", "eggs"}}

  ## Unknown commands or commands with the wrong number of
  arguments return an error:

  iex> Slugmenu.Server.Command.parse "UNKNOWN shopping eggs\n"
  {:error, :unknown_command}

  iex> Slugmenu.Server.Command.parse "GET shopping\n"
  {:error, :unknown_command}

  """
  def parse(line) do
    case String.split(line) do
      ["CREATE", bucket]             -> {:ok, {:create, bucket}}
      ["GET",    bucket, key]        -> {:ok, {:get,    bucket, key}}
      ["PUT",    bucket, key, value] -> {:ok, {:put,    bucket, key, value}}
      ["DELETE", bucket, key]        -> {:ok, {:delete, bucket, key}}
      _ -> {:error, :unknown_command}
    end
  end

  @doc """
  Runs the given command.
  """
  def run(command)

  def run({:create, bucket}) do
    SR.create(SR, bucket)
    {:ok, "OK\n"}
  end

  def run({:get, bucket, key}) do
    lookup bucket, fn pid ->
      value = SB.get(pid, key)
      {:ok, "#{value}\nOK\n"}
    end
  end

  def run({:put, bucket, key, value}) do
    lookup bucket, fn pid ->
      SB.put(pid, key, value)
      {:ok, "OK\n"}
    end
  end

  def run({:delete, bucket, key}) do
    lookup bucket, fn pid ->
      SB.delete(pid, key)
      {:ok, "OK\n"}
    end
  end

  defp lookup(bucket, callback) do
    case SR.lookup(SR, bucket) do
      {:ok, pid} -> callback.(pid)
      :error -> {:error, :not_found}
    end
  end
end
