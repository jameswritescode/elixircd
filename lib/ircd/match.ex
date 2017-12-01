defmodule IRCd.Match do
  def parse(line) do
    string = String.trim(to_string(line))

    [command|rest] = String.split(string, " ", global: false)
    string = Enum.join(rest, " ")
    [string|final] = String.split(string, ":", global: false)
    args = string
           |> String.trim
           |> String.split(" ", global: false)

    args = if final, do: args ++ final, else: args

    {:ok, String.to_atom(command), args}
  end
end
