defmodule Cluster.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_distributed_actor_cluster,
      version: "1.0.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Fault-tolerant distributed actor mesh and consistent hash ring in Elixir / OTP 27.",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Cluster.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/FelipeMadson/elixir-distributed-actor-cluster"}
    ]
  end
end
