defmodule EventuallyInconsistentPg do
  @moduledoc """
  `EventuallyInconsistentPg` implements a subset of the `:pg` API
  and only supports one global scope.
  """

  alias EventuallyInconsistentPg.Core

  def get_members(group), do: Core.get_members(group)

  def join(group, pidOrPids), do: Core.join(group, pidOrPids)

  def leave(group, pidOrPids), do: Core.leave(group, pidOrPids)

  def which_groups(), do: Core.which_groups()
end
