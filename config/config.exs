use Mix.Config

case Mix.env() do
  :dev ->
    config :mix_test_watch,
      clear: true,
      extra_extensions: [
        ".c"
      ]

  :test ->
    config :excheck, :number_iterations, 200
end
