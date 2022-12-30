defmodule EventuallyInconsistentPg.Util do
  @doc """
  We need this compiled as we cannot send the anonymous function to the
  peer nodes as they are not clustered with the origin node
  """
  def spawn_dummy_process(), do: Process.spawn(fn -> Process.sleep(:infinity) end, [])
end
