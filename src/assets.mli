module type Asset = sig
  type t

  val load : string -> t

  val get_handle : t -> int

  val to_string : t -> string
end

module VertexShader : sig
  include Asset

  exception Failed_to_compile_shader of string * string
end

module FragmentShader : sig
  include Asset

  exception Failed_to_compile_shader of string * string
end

module Program : sig
  include Asset

  exception Failed_to_link_shader_program of string * string * string

  val link : VertexShader.t -> FragmentShader.t -> t
end

module Texture : Asset
