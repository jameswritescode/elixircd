defmodule IRCd.Handler do
  require Logger

  @rpl [
    welcome: "001",
    yourhost: "002",
    created: "003",
    myinfo: "004"
  ]

  def process({:NICK, args}, user) do
    user = %IRCd.User{user|host: IRCd.User.hostmask(user), nick: List.first(args), uuid: UUID.uuid1}

    GenServer.cast(IRCd.Server, {:register_user, user})

    {user, []}
  end

  # TODO: `host` support needs to be implemented
  # TODO: 002, 003, 004
  def process({:USER, [username, _host, _, name]}, user) do
    user = %IRCd.User{user|user: username, name: name}

    GenServer.cast(IRCd.Server, {:update_user, user})

    host = Application.get_env(:ircd, :host)
    network = Application.get_env(:ircd, :name)

    {user, [
      ":#{host} #{@rpl[:welcome]} #{user.nick} Welcome to #{network}",
      ":#{host} #{@rpl[:yourhost]} #{user.nick} Your host is #{host}, running version TODO",
      ":#{host} #{@rpl[:created]} #{user.nick} created",
      ":#{host} #{@rpl[:myinfo]} #{user.nick} myinfo",

    ]}
  end

  def process(info, actor) do
    msg = """
    IRCd.Handler, Uncaught:

      INFO: #{inspect(info)}

      ACTOR: #{inspect(actor)}
    """

    Logger.debug(msg)

    {actor, []}
  end
end
