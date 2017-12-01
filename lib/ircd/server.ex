defmodule IRCd.Server do
  use GenServer

  require Logger

  defstruct users: %{}

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Logger.info("Launching IRCd for #{Application.get_env(:ircd, :name)}")

    port = Application.get_env(:ircd, :port)

    case :gen_tcp.listen(port, [packet: :line, reuseaddr: true]) do
      {:ok, socket} ->
        Logger.info("Accepting connections on port #{port}")
        spawn(IRCd.Server, :accept_connection, [socket])

        {:ok, %IRCd.Server{}}
      {:error, reason} ->
        Logger.error("Error listening on port #{port}: #{reason}")
        exit(reason)
    end
  end

  def accept_connection(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        {:ok, pid} = IRCd.User.start_link({:global, :erlang.make_ref})
        :ok = :gen_tcp.controlling_process(client, pid)
        GenServer.cast(pid, {:create, client})
      {:error, reason} ->
        Logger.error("Could not accept client: #{inspect(reason)}")
        exit(reason)
    end

    accept_connection(socket)
  end

  def handle_cast({:register_user, user}, state) do
    state = %IRCd.Server{state|users: Map.put(state.users, user.uuid, user)}

    {:noreply, state}
  end

  def handle_cast({:update_user, user}, state) do
    {_, users} = Map.get_and_update(state.users, user.uuid, fn c ->
      {c, user}
    end)

    state = %IRCd.Server{state|users: users}

    {:noreply, state}
  end

  def handle_cast({:unregister_user, user}, state) do
    :gen_tcp.close(user.socket)

    state = %IRCd.Server{state|users: Map.delete(state.users, user.uuid)}

    {:noreply, state}
  end
end
