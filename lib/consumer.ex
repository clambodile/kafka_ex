defmodule Kafka.Consumer do
  use GenServer

  def init({broker_list, client_id}) do
    {:ok, %{broker_list: broker_list, client_id: client_id, correlation_id: 1}}
  end

  def handle_call({:subscribe, topic_list}, from, %{broker_list: broker_list, client_id: client_id} = state) do
    case Kafka.Connection.connect(broker_list) do
      {:ok, connection} ->
        {broker_map, topic_map} =
          Kafka.Metadata.get_metadata(connection, state.correlation_id, client_id)
        Kafka.Connection.close(connection)
        handle_call({:subscribe, topic_list},
                     from,
                     %{brokers: broker_map, topics: topic_map})

      error             -> {:reply, error, state}
    end
  end

  def handle_call({:subscribe, topic_list}, _, state) do
    IO.inspect({:reply, :ok, Enum.reduce(topic_list, state, &do_subscribe/2)})
  end

  defp do_subscribe(topic, %{brokers: broker_map, topics: topic_map} = state) do
    state
  end

  def start(broker_list, client_id) do
    GenServer.start(__MODULE__, {broker_list, client_id})
  end

  def subscribe(consumer, topic_list) do
    GenServer.call(consumer, {:subscribe, topic_list})
  end
end
