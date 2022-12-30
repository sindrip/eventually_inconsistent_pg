defmodule EventuallyInconsistentPgClusterTest do
  use ExUnitCluster.Case, async: true

  test "distributed EIPG simple", %{cluster: cluster} do
    n1 = ExUnitCluster.start_node(cluster)
    n2 = ExUnitCluster.start_node(cluster)

    group = "group"

    n1_pid =
      ExUnitCluster.call(cluster, n1, EventuallyInconsistentPg.Util, :spawn_dummy_process, [])

    # Observe the group with a single pid on both nodes
    ExUnitCluster.call(cluster, n1, EventuallyInconsistentPg, :join, [group, n1_pid])

    n1_groups = ExUnitCluster.call(cluster, n1, EventuallyInconsistentPg, :which_groups, [])
    n2_groups = ExUnitCluster.call(cluster, n2, EventuallyInconsistentPg, :which_groups, [])

    assert ^n1_groups = ^n2_groups = [group]

    group_n1_pids =
      ExUnitCluster.call(cluster, n1, EventuallyInconsistentPg, :get_members, [group])

    group_n2_pids =
      ExUnitCluster.call(cluster, n2, EventuallyInconsistentPg, :get_members, [group])

    assert ^group_n1_pids = ^group_n2_pids = [n1_pid]
  end

  test "distributed EIPG monitoring across nodes", %{cluster: cluster} do
    n1 = ExUnitCluster.start_node(cluster)
    n2 = ExUnitCluster.start_node(cluster)

    group = "group"

    n1_pid =
      ExUnitCluster.call(cluster, n1, EventuallyInconsistentPg.Util, :spawn_dummy_process, [])

    # Observe the group with a single pid on both nodes
    ExUnitCluster.call(cluster, n1, EventuallyInconsistentPg, :join, [group, n1_pid])

    assert_consistent_groups(cluster, [n1, n2], [group])

    # kill the process and observe it being gone on both nodes
    ExUnitCluster.call(cluster, n1, Process, :exit, [n1_pid, :kill])

    assert_consistent_groups(cluster, [n1, n2], [])
  end

  test "distributed EIPG inconsistent after netsplit", %{cluster: cluster} do
    n1 = ExUnitCluster.start_node(cluster)
    n2 = ExUnitCluster.start_node(cluster)

    group = "group"

    n1_pid =
      ExUnitCluster.call(cluster, n1, EventuallyInconsistentPg.Util, :spawn_dummy_process, [])

    # Observe the group with a single pid on both nodes
    ExUnitCluster.call(cluster, n1, EventuallyInconsistentPg, :join, [group, n1_pid])
    Process.sleep(100)

    assert_consistent_groups(cluster, [n1, n2], [group])

    # Disconnect the nodes and observe inconsistent data even after reconnection
    ExUnitCluster.call(cluster, n1, Node, :disconnect, [n2])
    refute_consistent_groups(cluster, [n1, n2])

    ExUnitCluster.call(cluster, n1, Node, :connect, [n2])
    refute_consistent_groups(cluster, [n1, n2])
  end

  defp node_groups_members(cluster, nodes) do
    for node <- nodes do
      node_groups = ExUnitCluster.call(cluster, node, EventuallyInconsistentPg, :which_groups, [])

      group_members =
        Enum.reduce(node_groups, Map.new(), fn g, acc ->
          members = ExUnitCluster.call(cluster, node, EventuallyInconsistentPg, :get_members, [g])

          Map.put(acc, g, Enum.sort(members))
        end)

      {node_groups, group_members}
    end
    |> Enum.unzip()
  end

  defp refute_consistent_groups(cluster, nodes) do
    {_node_groups, node_members} = node_groups_members(cluster, nodes)

    set_size =
      node_members
      |> MapSet.new()
      |> MapSet.size()

    refute set_size == 1
  end

  defp assert_consistent_groups(cluster, nodes, expected_groups) do
    {node_groups, node_members} = node_groups_members(cluster, nodes)

    Enum.each(node_groups, fn node_group ->
      assert Enum.sort(node_group) == Enum.sort(expected_groups)
    end)

    set_size =
      node_members
      |> MapSet.new()
      |> MapSet.size()

    assert set_size == 1
  end
end
