defmodule PhoenixDSK.RestClientAgent do
  @doc """
  Start the agent with the given 'name'. We can have many of these.
  name must be an atom. In this case, the name is client: and we're only
  goint to have one, for now, that points to the learnserver we set
  in config.exs.
  """
  def start_link() do
    learnserver = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    Agent.start_link(fn -> %{client: LearnRestClient.start_client(learnserver)} end, name: :RCA)
  end

end
