defmodule IRCd.User do
  use GenServer

  require Logger

  defstruct [:ip, :port, :socket]

  def start_link(ref) do
    GenServer.start_link(__MODULE__, :ok, name: ref)
  end

  def init(:ok) do
    {:ok, %IRCd.User{}}
  end

  def handle_cast({:create, socket}, state) do
    {:ok, {ip, port}} = :inet.peername(socket)
    ip_string = to_string(:inet_parse.ntoa(ip))

    {:noreply, %IRCd.User{state | ip: ip_string, port: port, socket: socket}}
  end

  def handle_info(info, state) do
    Logger.debug("Uncaught: #{inspect(info)}")

    {:noreply, state}
  end
end
