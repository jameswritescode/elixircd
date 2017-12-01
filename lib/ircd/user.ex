defmodule IRCd.User do
  @moduledoc false

  use GenServer

  require Logger

  defstruct [:host, :ip, :name, :nick, :mask, :port, :socket, :user, :uuid]

  def start_link(ref) do
    GenServer.start_link(__MODULE__, :ok, name: ref)
  end

  def init(:ok) do
    {:ok, %IRCd.User{}}
  end

  # TODO: send connection notices
  def handle_cast({:create, socket}, state) do
    {:ok, {ip, port}} = :inet.peername(socket)
    ip_string = to_string(:inet_parse.ntoa(ip))

    host = case :inet.gethostbyaddr(ip) do
      {:ok, {:hostent, hostname, _, _, _, _}} -> to_string(hostname)
      {:error, _} -> to_string(ip_string)
    end

    {:noreply, %IRCd.User{state | host: host, ip: ip_string, port: port, socket: socket}}
  end

  def handle_info({:tcp, _socket, data}, state) do
    Logger.debug("<<< #{inspect(data)}")

    {:ok, command, args} = IRCd.Match.parse(data)
    {state, replies} = IRCd.Handler.process({command, args}, state)

    write(state.socket, replies)

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _pid}, state) do
    GenServer.cast(IRCd.Server, {:unregister_user, state})

    {:noreply, state}
  end

  def handle_info(info, state) do
    msg = """
    IRCd.Server, Uncaught:

      INFO: #{inspect(info)}
    """

    Logger.debug(msg)

    {:noreply, state}
  end

  def hostmask(user) do
    "#{user.nick}!#{user.user}@#{user.host}"
  end

  defp write(socket, data) when is_list(data) do
    write(socket, Enum.join(data, "\r\n"))
  end

  defp write(socket, data) when is_binary(data) do
    unless data == "" do
      Logger.debug(">>> #{data}")

      :gen_tcp.send(socket, data)
    end
  end
end
