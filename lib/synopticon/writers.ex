defmodule Synopticon.Writers do
  @moduledoc """
  Loads locally configured writer emails.
  """

  @default_path "config/local/writers.txt"

  def authorized?(email), do: authorized?(path(), email)

  def authorized?(path, email) when is_binary(email) do
    normalized = normalize(email)
    normalized != "" and MapSet.member?(emails(path), normalized)
  end

  def authorized?(_path, _email), do: false

  def emails(path \\ path()) do
    path
    |> File.read()
    |> case do
      {:ok, content} -> parse(content)
      {:error, :enoent} -> MapSet.new()
      {:error, _reason} -> MapSet.new()
    end
  end

  def parse(content) do
    content
    |> String.split(["\r\n", "\n", "\r"])
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&ignored?/1)
    |> Enum.map(&normalize/1)
    |> Enum.reject(&(&1 == ""))
    |> MapSet.new()
  end

  defp ignored?(""), do: true
  defp ignored?("#" <> _comment), do: true
  defp ignored?("//" <> _comment), do: true
  defp ignored?(_line), do: false

  defp normalize(email), do: email |> String.trim() |> String.downcase()

  defp path do
    :synopticon
    |> Application.get_env(:writers_path, @default_path)
    |> Path.expand(File.cwd!())
  end
end
