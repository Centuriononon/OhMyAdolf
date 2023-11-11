[
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs"
  ],
  import_deps: [:plug, :plug_cowboy],
  line_length: 80
]
