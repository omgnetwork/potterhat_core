# Copyright 2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule PotterhatCore.NodeConfig do
  @moduledoc """
  Provides overall information about nodes.
  """

  @enforce_keys [:id, :label, :client_type, :rpc, :ws, :priority]
  defstruct [:id, :label, :client_type, :rpc, :ws, :priority, :node_registry]

  @doc """
  Builds a NodeConfig struct from the given map of inputs with string keys.
  """
  def from_input_map!(map) do
    # The "id" is converted to atom here so it can be used as GenServer identifier etc.
    # The String.to_atom/1 should be safe here as the node configurations should
    # only be set by administrators.
    %__MODULE__{
      id: Map.fetch!(map, "id") |> String.to_atom(),
      label: Map.fetch!(map, "label"),
      client_type: Map.fetch!(map, "client_type"),
      rpc: Map.fetch!(map, "rpc"),
      ws: Map.fetch!(map, "ws"),
      priority: Map.fetch!(map, "priority") |> String.to_integer(),
      node_registry: nil
    }
  end

  @doc """
  Retrieve the list of all node configurations.
  """
  @spec all() :: [%PotterhatCore.NodeConfig{}]
  def all, do: Application.get_env(:potterhat_core, :nodes, [])

  @doc """
  Retrieve the total number of node configurations.
  """
  @spec count() :: non_neg_integer()
  def count, do: length(all())
end
