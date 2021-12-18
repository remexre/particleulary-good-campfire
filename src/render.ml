open Assets
open Tgl3
open Util

type renderable = {
  program : Program.t;
  vbo : Buffer.t;
  model_matrix : Mat4.t;
  texture : Texture.t;
}

type scene = {
  vao : VAO.t;
  debug_program : Program.t;
  debug_texture : Texture.t;
  particle_system : Particle_system.particle_system;
  mutable opaque_objects : renderable array;
  mutable camera : Camera.t;
  mutable proj_matrix : Mat4.t;
}

let init_scene (particle_system : Particle_system.particle_system)
    (camera : Camera.t) : scene =
  let vert_default = VertexShader.load "shaders/default" in
  let _frag_debug = FragmentShader.load "shaders/debug" in
  let frag_tex_no_lighting = FragmentShader.load "shaders/tex_no_lighting" in
  let debug_program = Program.link vert_default frag_tex_no_lighting in
  let example_obj =
    {
      program = debug_program;
      vbo = Obj_loader.load_file ~path:"assets/campfire/OBJ/Campfire.obj";
      model_matrix =
        Mat4.(translate ~x:0.0 ~y:0.0 ~z:(-100.0) * scale_uniform 0.01);
      texture = Texture.load "debug";
    }
  in
  {
    vao = VAO.make ();
    debug_program;
    debug_texture = Texture.load "debug";
    particle_system;
    opaque_objects = [| example_obj |];
    camera;
    proj_matrix =
      Mat4.perspective ~fovy:(Float.pi /. 2.0) ~aspect:(16.0 /. 9.0) ~near:0.1
        ~far:1000.0;
  }

let bind_matrix (program : Program.t) (name : string) : Mat4.t -> unit =
  let location = Gl.get_uniform_location (Program.get_handle program) name in
  Gl.uniform_matrix4fv location 1 false % Mat4.to_bigarray

let enable_attrib (program : Program.t) (name : string) ~(offset : int)
    ~(count : int) ~(stride : int) : unit =
  let index = Gl.get_attrib_location (Program.get_handle program) name in
  Gl.enable_vertex_attrib_array index;
  Gl.vertex_attrib_pointer index count Gl.float false stride (`Offset offset)

let disable_attrib (program : Program.t) (name : string) : unit =
  let index = Gl.get_attrib_location (Program.get_handle program) name in
  Gl.disable_vertex_attrib_array index

let render_one (renderable : renderable) (view_matrix : Mat4.t)
    (proj_matrix : Mat4.t) : unit =
  (* Bind the program. *)
  Gl.use_program (Program.get_handle renderable.program);
  (* Bind the MVP matrices. *)
  bind_matrix renderable.program "model" renderable.model_matrix;
  bind_matrix renderable.program "view" view_matrix;
  bind_matrix renderable.program "proj" proj_matrix;

  (* Bind the VBO. *)
  Gl.bind_buffer Gl.array_buffer (Buffer.get_handle renderable.vbo);
  (* Enable the attributes and set their offsets. *)
  let stride = 32 in
  enable_attrib renderable.program "msPosition" ~offset:0 ~count:3 ~stride;
  enable_attrib renderable.program "msNormals" ~offset:12 ~count:3 ~stride;
  enable_attrib renderable.program "texCoords" ~offset:24 ~count:2 ~stride;

  (* Bind the texture. *)
  Gl.active_texture Gl.texture0;
  Gl.bind_texture Gl.texture_2d (Texture.get_handle renderable.texture);
  Gl.uniform1i
    (Gl.get_uniform_location (Program.get_handle renderable.program) "tex")
    0;

  (* Draw the model! *)
  Gl.draw_arrays Gl.triangles 0 (Buffer.length renderable.vbo / 32);

  (* Disable the attributes. *)
  disable_attrib renderable.program "msPosition";
  disable_attrib renderable.program "msNormals";
  disable_attrib renderable.program "texCoords"

let render (scene : scene) : unit =
  VAO.bind scene.vao;

  (* Enable the depth test. *)
  Gl.enable Gl.depth_test;
  Gl.depth_func Gl.less;

  (* Clear the previous frame. *)
  Gl.clear_color 0.0 0.0 0.2 1.0;
  Gl.clear_depth 1.0;
  Gl.clear (Int.logor Gl.color_buffer_bit Gl.depth_buffer_bit);

  (* Render the objects other than the particles. *)
  Array.iter
    (fun renderable ->
      render_one renderable (Camera.view scene.camera) scene.proj_matrix)
    scene.opaque_objects;

  (* Disable the depth test. *)
  Gl.disable Gl.depth_test
