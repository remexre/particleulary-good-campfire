open Assets
open Tgl3
open Util

type renderable = { program : Program.t; vbo : Buffer.t; model_matrix : Mat4.t }

type scene = {
  vao : VAO.t;
  debug_program : Program.t;
  debug_texture : Texture.t;
  particle_system : Particle_system.particle_system;
  mutable opaque_objects : renderable array;
  mutable view_matrix : Mat4.t;
  mutable proj_matrix : Mat4.t;
}

let init_scene (particle_system : Particle_system.particle_system) : scene =
  let vert_default = VertexShader.load "shaders/default" in
  let frag_debug = FragmentShader.load "shaders/debug" in
  let debug_program = Program.link vert_default frag_debug in
  let example_obj =
    {
      program = debug_program;
      vbo = Obj_loader.load_file ~path:"assets/campfire/OBJ/Campfire.obj";
      model_matrix =
        Mat4.(translate ~x:0.0 ~y:0.0 ~z:(-100.0) * scale_uniform 0.01);
    }
  in
  {
    vao = VAO.make ();
    debug_program;
    debug_texture = Texture.load "debug";
    particle_system;
    opaque_objects = [| example_obj |];
    view_matrix = Mat4.identity;
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

  (* Draw the model! *)
  Gl.draw_arrays Gl.triangles 0 (Buffer.length renderable.vbo / 32);

  (* Disable the attributes. *)
  disable_attrib renderable.program "msPosition";
  disable_attrib renderable.program "msNormals";
  disable_attrib renderable.program "texCoords"

let render (scene : scene) : unit =
  VAO.bind scene.vao;
  Gl.clear_color 0.0 0.0 0.0 1.0;
  Gl.clear_depth 0.0;
  Gl.clear (Int.logor Gl.color_buffer_bit Gl.depth_buffer_bit);
  Array.iter
    (fun renderable ->
      render_one renderable scene.view_matrix scene.proj_matrix)
    scene.opaque_objects
