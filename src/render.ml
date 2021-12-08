open Assets
open Tgl3

type scene = {
  debug_program : Program.t;
  debug_texture : Texture.t;
  particle_system : Particle_system.particle_system;
}

let init_scene (particle_system : Particle_system.particle_system) : scene =
  let vert_default = VertexShader.load "shaders/default" in
  let frag_debug = FragmentShader.load "shaders/debug" in
  {
    debug_program = Program.link vert_default frag_debug;
    debug_texture = Texture.load "debug";
    particle_system;
  }

let render (_scene : scene) : unit =
  Gl.clear_color 0.0 0.0 0.0 1.0;
  Gl.clear_depth 0.0;
  Gl.clear (Int.logor Gl.color_buffer_bit Gl.depth_buffer_bit)
