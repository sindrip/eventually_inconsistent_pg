defmodule EventuallyInconsistentPgTest do
  use ExUnit.Case, async: true

  test "Adding local process is reflected in known groups and membership" do
    # No groups known at startup
    assert [] = EventuallyInconsistentPg.which_groups()

    test_pid = self()

    # We can join a group with a pid or list of pids
    group = "group"
    EventuallyInconsistentPg.join(group, test_pid)
    EventuallyInconsistentPg.join(group, [test_pid, test_pid])

    assert [^group] = EventuallyInconsistentPg.which_groups()
    assert [^test_pid, ^test_pid, ^test_pid] = EventuallyInconsistentPg.get_members(group)

    # We can leave a group with a pid or list of pids
    EventuallyInconsistentPg.leave(group, [test_pid, test_pid])
    assert [^test_pid] = EventuallyInconsistentPg.get_members(group)

    EventuallyInconsistentPg.leave(group, test_pid)
    assert [] = EventuallyInconsistentPg.get_members(group)

    # Multiple pids joining same or different group
    other_pid = Process.spawn(fn -> Process.sleep(:infinity) end, [])
    EventuallyInconsistentPg.join(group, [test_pid, other_pid])

    assert Enum.sort([test_pid, other_pid]) ===
             Enum.sort(EventuallyInconsistentPg.get_members(group))

    another_group = "another_group"
    EventuallyInconsistentPg.join(another_group, [other_pid])

    assert Enum.sort([group, another_group]) == Enum.sort(EventuallyInconsistentPg.which_groups())

    # Killing a process cleans up its entries
    Process.exit(other_pid, :kill)
    Process.sleep(1)

    assert [^group] = EventuallyInconsistentPg.which_groups()
    assert [^test_pid] = EventuallyInconsistentPg.get_members(group)
    assert [] = EventuallyInconsistentPg.get_members(another_group)
  end
end
