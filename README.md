# particleulary-good-campfire

A particle-system-based campfire simulation.

## Building

### With Dune

Have OPAM installed.
(Tested inside the `ocaml/opam:0d6f74da86f4` Docker image.) 

```
$ sudo apt update
$ sudo apt install libffi-dev libglfw3-dev pkg-config
$ opam install glfw-ocaml imagelib tgls
$ dune build
$ ./_build/install/default/bin/particleulary-good-campfire
```

### With Nix

Have Nix 2.4+ installed, with the `nix-command` feature enabled.

```
$ nix build
$ ls ./result/bin/particleulary-good-campfire
```
