open Tgl3

module type Asset = sig
  type t

  val load : string -> t

  val to_string : t -> string
end

module type OpenGLResource = sig
  type t

  val get_handle : t -> int

  val to_string : t -> string
end

module VertexShader : sig
  include Asset

  include OpenGLResource with type t := t

  exception Failed_to_compile_shader of string * string
end

module FragmentShader : sig
  include Asset

  include OpenGLResource with type t := t

  exception Failed_to_compile_shader of string * string
end

module Program : sig
  include Asset

  include OpenGLResource with type t := t

  exception Failed_to_link_shader_program of string * string * string

  val link : VertexShader.t -> FragmentShader.t -> t
end

module Texture : sig
  include Asset

  include OpenGLResource with type t := t
end

module Buffer : sig
  include OpenGLResource

  type float_array =
    (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t

  val make_uninit :
    kind:string ->
    name:string ->
    target:Gl.enum ->
    usage:Gl.enum ->
    size:int ->
    t

  val make_static_vbo : name:string -> data:float_array -> t

  val make_ubo : name:string -> data:float_array -> t

  val free : t -> unit

  val length : t -> int
end

module VAO : sig
  include OpenGLResource

  val make : unit -> t

  val bind : t -> unit
end
