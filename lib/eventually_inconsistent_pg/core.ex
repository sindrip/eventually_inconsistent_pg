defmodule EventuallyInconsistentPg.Core do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_members(group), do: GenServer.call(__MODULE__, {:get_members, group})

  def join(group, pidOrPids),
    do: GenServer.abcast(nodes(), __MODULE__, {:join, group, pidOrPids})

  def leave(group, pidOrPids),
    do: GenServer.abcast(nodes(), __MODULE__, {:leave, group, pidOrPids})

  def which_groups(), do: GenServer.call(__MODULE__, :which_groups)

  @impl GenServer
  def init(_opts) do
    {:ok, Map.new()}
  end

  @impl GenServer
  def handle_call({:get_members, group}, _from, state) do
    members =
      Enum.reduce(state, [], fn {pid, {_ref, pid_groups}}, acc ->
        no_times_in_group = Enum.filter(pid_groups, &(&1 === group)) |> length()

        List.duplicate(pid, no_times_in_group) ++ acc
      end)

    {:reply, members, state}
  end

  @impl GenServer
  def handle_call(:which_groups, _from, state) do
    groups =
      Enum.reduce(state, MapSet.new(), fn {_pid, {_ref, groups}}, acc ->
        MapSet.union(MapSet.new(groups), acc)
      end)
      |> MapSet.to_list()

    {:reply, groups, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {^ref, _groups} = Map.get(state, pid)
    state = Map.delete(state, pid)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:join, group, pidOrPids}, state) do
    state = do_join(state, group, pidOrPids)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:leave, group, pidOrPids}, state) do
    state = do_leave(state, group, pidOrPids)

    {:noreply, state}
  end

  defp do_join(state, group, pidOrPids) when is_pid(pidOrPids),
    do: do_join(state, group, [pidOrPids])

  defp do_join(state, group, pidOrPids) when is_list(pidOrPids) do
    Enum.reduce(pidOrPids, state, fn pid, acc ->
      {_, new_map} =
        Map.get_and_update(acc, pid, fn groups ->
          case groups do
            nil ->
              ref = Process.monitor(pid)
              {nil, {ref, [group]}}

            {ref, groups} ->
              {groups, {ref, [group | groups]}}
          end
        end)

      new_map
    end)
  end

  defp do_leave(state, group, pidOrPids) when is_pid(pidOrPids),
    do: do_leave(state, group, [pidOrPids])

  defp do_leave(state, group, pidOrPids) when is_list(pidOrPids) do
    Enum.reduce(pidOrPids, state, fn pid, acc ->
      case Map.get(acc, pid) do
        nil ->
          acc

        {ref, [^group]} ->
          Process.demonitor(ref)
          Map.delete(acc, pid)

        {ref, pid_groups} ->
          Map.put(acc, pid, {ref, List.delete(pid_groups, group)})
      end
    end)
  end

  defp nodes, do: Node.list([:visible, :this])
end
