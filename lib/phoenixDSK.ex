# File: phoenixDSK.ex
# Author: Mark Kauffman - used the generate scripts to create this.
# 2017.03.27 MBK - Adding code to load the LearnRestClient here.
#   We start another supervisor to load the LearnClient.

defmodule PhoenixDSK do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(PhoenixDSK.Repo, []),
      # Start the endpoint when the application starts
      supervisor(PhoenixDSK.Endpoint, []),
      # Start your own worker by calling: PhoenixDSK.Worker.start_link(arg1, arg2, arg3)
      # worker(PhoenixDSK.Worker, [arg1, arg2, arg3]),
      worker(PhoenixDSK.RestClientAgent,[]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixDSK.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PhoenixDSK.Endpoint.config_change(changed, removed)
    :ok
  end
end
