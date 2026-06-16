defmodule Synopticon.Env do
  @moduledoc false

  def load_dotenv(dir \\ File.cwd!()) do
    path = Path.join(dir, ".env")

    if File.regular?(path) do
      path
      |> File.stream!([], :line)
      |> Enum.each(&load_dotenv_line/1)
    end

    :ok
  end

  def load_and_configure! do
    load_dotenv()
  end

  defp load_dotenv_line(line) do
    line =
      line
      |> String.trim()
      |> String.trim_leading("export ")

    cond do
      line == "" ->
        :ok

      String.starts_with?(line, "#") ->
        :ok

      true ->
        case String.split(line, "=", parts: 2) do
          [key, value] -> put_new_env(String.trim(key), parse_value(value))
          _ -> :ok
        end
    end
  end

  defp put_new_env("", _value), do: :ok

  defp put_new_env(key, value) do
    if System.get_env(key) in [nil, ""] do
      System.put_env(key, value)
    end

    :ok
  end

  defp parse_value(value) do
    value
    |> String.trim()
    |> unquote_value()
  end

  defp unquote_value(<<quote, rest::binary>>) when quote in [?", ?'] do
    size = byte_size(rest)

    if size > 0 and :binary.last(rest) == quote do
      binary_part(rest, 0, size - 1)
    else
      <<quote, rest::binary>>
    end
  end

  defp unquote_value(value), do: value
end
