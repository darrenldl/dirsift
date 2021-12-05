FROM ocaml/opam
USER root
RUN opam install dune ocamlformat containers fmt fileutils cmdliner timere timere-parse otoml dune-build-info
