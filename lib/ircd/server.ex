defmodule IRCd.Server do
  use GenServer

  require Logger

  defstruct users: []

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
        GenServer.cast(IRCd.User, {:create, client})
      {:error, reason} ->
        Logger.error("Could not accept client: #{inspect(reason)}")
        exit(reason)
    end

    accept_connection(socket)
  end
end
