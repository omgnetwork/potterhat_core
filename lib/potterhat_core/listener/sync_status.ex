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

defmodule PotterhatCore.Listener.SyncStatus do
  @moduledoc """
  Listens for sync status events.
  """
  use WebSockex

  @subscription_id 2

  #
  # Client API
  #

  @doc """
  Starts a GenServer that listens to syncStatus events.
  """
  @spec start_link(String.t(), Keyword.t()) :: {:ok, pid()} | no_return()
  def start_link(url, opts) do
    name = String.to_atom("#{opts[:node_id]}_syncstatus")
    opts = Keyword.put(opts, :name, name)

    case WebSockex.start_link(url, __MODULE__, opts, opts) do
      {:ok, pid} ->
        _ = listen(pid)
        {:ok, pid}

      error ->
        error
    end
  end

  defp listen(pid) do
    payload = %{
      jsonrpc: "2.0",
      id: @subscription_id,
      method: "eth_subscribe",
      params: [
        "syncing"
      ]
    }

    WebSockex.send_frame(pid, {:text, Jason.encode!(payload)})
  end

  #
  # Server API
  #

  @doc false
  @spec init(Keyword.t()) :: {:ok, map()}
  def init(opts) do
    state = %{
      label: opts[:label],
      subscriber: opts[:subscriber]
    }

    {:ok, state}
  end

  @doc false
  @impl true
  def handle_frame({_type, msg}, state) do
    {:ok, data} = Jason.decode(msg)
    state = do_handle_frame(data, state)
    {:ok, state}
  end

  #
  # Handle received websocket frames
  #

  # Successful subscription
  defp do_handle_frame(%{"result" => result}, state) when is_binary(result) do
    meta = %{
      node_id: state[:node_id],
      node_label: state[:node_label]
    }

    _ = :telemetry.execute([:event_listener, :sync_status, :subscribe_success], %{}, meta)
    state
  end

  # Failed subscription
  defp do_handle_frame(%{"error" => error}, state) do
    meta = %{
      node_id: state[:node_id],
      node_label: state[:node_label],
      error: error
    }

    _ = :telemetry.execute([:event_listener, :sync_status, :subscribe_failed], %{}, meta)
    state
  end

  # Sync stopped
  defp do_handle_frame(%{"params" => %{"result" => false}}, state) do
    meta = %{
      node_id: state[:node_id],
      node_label: state[:node_label]
    }

    :telemetry.execute([:event_listener, :sync_status, :sync_stopped], %{}, meta)
  end

  # Sync started
  defp do_handle_frame(%{"params" => _} = data, state) do
    measurements = %{
      starting_block: data["params"]["status"]["StartingBlock"],
      current_block: data["params"]["status"]["CurrentBlock"],
      highest_block: data["params"]["status"]["HighestBlock"]
    }

    meta = %{
      node_id: state[:node_id],
      node_label: state[:node_label]
    }

    _ = :telemetry.execute([:event_listener, :sync_status, :sync_started], measurements, meta)
    state
  end
end
