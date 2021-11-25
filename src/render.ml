open Assets
open Tgl3

type t = { debug_program : Program.t; debug_texture : Texture.t }

let init () : t =
  let vert_default = VertexShader.load "shaders/default" in
  let frag_debug = FragmentShader.load "shaders/debug" in
  {
    debug_program = Program.link vert_default frag_debug;
    debug_texture = Texture.load "debug";
  }

let render (state : t) : unit =
  Gl.clear_color 0.0 0.0 0.0 1.0;
  Gl.clear_depth 0.0;
  Gl.clear (Int.logor Gl.color_buffer_bit Gl.depth_buffer_bit)
