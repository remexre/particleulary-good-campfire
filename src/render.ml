open Assets
open Tgl3
open Util

type renderable = {
  program : Program.t;
  vbo : Buffer.t;
  model_matrix : Mat4.t;
  material : Mtl_loader.mat;
}

type node = One of renderable | Nodes of node list

let rec each_renderable (f : renderable -> unit) = function
  | One renderable -> f renderable
  | Nodes subnodes -> List.iter (each_renderable f) subnodes

let load_obj program model_matrix path : node =
  Obj_loader.load_file ~path
  |> List.map (fun (material, vbo) ->
         One { program; vbo; model_matrix; material })
  |> fun subnodes -> Nodes subnodes

type scene = {
  vao : VAO.t;
  particle_system : Particle_system.t;
  sphere_vbo : Buffer.t;
  particle_program : Program.t;
  mutable opaque_objects : node;
  mutable camera : Camera.t;
  mutable proj_matrix : Mat4.t;
}

let init_scene (particle_system : Particle_system.t) (camera : Camera.t) : scene
    =
  (* Load the shaders we're going to use. *)
  let vert_default = VertexShader.load "assets/shaders/default" in
  let vert_particle = VertexShader.load "assets/shaders/particle" in
  let frag_debug = FragmentShader.load "assets/shaders/debug" in
  let _frag_tex_no_lighting =
    FragmentShader.load "assets/shaders/tex_no_lighting"
  in
  let debug_program = Program.link vert_default frag_debug
  and particle_program = Program.link vert_particle frag_debug in

  (* Load the objects. *)
  let campfire =
    load_obj debug_program
      Mat4.(translate ~x:0.0 ~y:0.0 ~z:(-100.0) * scale_uniform 0.01)
      "assets/campfire/OBJ/Campfire.obj"
  and ground =
    load_obj debug_program
      Mat4.(translate ~x:0.0 ~y:0.0 ~z:0.0 * scale_uniform 5000.0)
      "assets/rectangle.obj"
  and trees =
    let conifer = "assets/conifer_macedonian_pine/conifer_macedonian_pine.obj" in
    let ts = [
      (load_obj debug_program
        Mat4.(translate ~x:(25.0) ~y:(0.0) ~z:(-1000.0) * scale_uniform (0.005)) conifer);
      (load_obj debug_program
        Mat4.(translate ~x:(-400.0) ~y:(0.0) ~z:(-2000.0) * scale_uniform (0.007)) conifer);
      (load_obj debug_program
        Mat4.(translate ~x:(700.0) ~y:(0.0) ~z:(-50.0) * scale_uniform (0.01)) conifer);
      (load_obj debug_program
        Mat4.(translate ~x:(300.0) ~y:(0.0) ~z:(2000.0) * scale_uniform (0.008)) conifer);
      (load_obj debug_program
        Mat4.(translate ~x:(-800.0) ~y:(0.0) ~z:(1500.0) * scale_uniform (0.02)) conifer);
      ] in
    Nodes (ts)
  in
  (* Load the sphere model. *)
  let sphere_vbo =
    snd (List.nth (Obj_loader.load_file ~path:"assets/sphere.obj") 1)
  in

  (* Make and bind the VAO. *)
  let vao = VAO.make () in
  VAO.bind vao;

  (* Enable the depth test. *)
  Gl.enable Gl.depth_test;
  Gl.depth_func Gl.less;

  (* Enable MSAA. *)
  Gl.enable Gl.multisample;

  (* Make the scene. *)
  {
    vao;
    particle_system;
    sphere_vbo;
    particle_program;
    opaque_objects = Nodes [ campfire; ground; trees ];
    camera;
    proj_matrix =
      Mat4.perspective ~fovy:(Float.pi /. 2.0) ~aspect:(16.0 /. 9.0) ~near:0.1
        ~far:1000.0;
  }

let bind_matrix (program : Program.t) (name : string) : Mat4.t -> unit =
  let location = Gl.get_uniform_location (Program.get_handle program) name in
  Gl.uniform_matrix4fv location 1 false % Mat4.to_bigarray

let enable_attrib_with_divisor (program : Program.t) (name : string)
    ~(offset : int) ~(count : int) ~(stride : int) ~(divisor : int) : unit =
  let index = Gl.get_attrib_location (Program.get_handle program) name in
  Gl.enable_vertex_attrib_array index;
  Gl.vertex_attrib_pointer index count Gl.float false stride (`Offset offset);
  Gl.vertex_attrib_divisor index divisor

let enable_attrib (program : Program.t) (name : string) ~(offset : int)
    ~(count : int) ~(stride : int) : unit =
  enable_attrib_with_divisor program name ~offset ~count ~stride ~divisor:0

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

  (* Bind the texture, if there is one. *)
  Option.iter
    (fun texture ->
      Gl.active_texture Gl.texture0;
      Gl.bind_texture Gl.texture_2d (Texture.get_handle texture);
      Gl.uniform1i
        (Gl.get_uniform_location (Program.get_handle renderable.program) "tex")
        0)
    renderable.material.diffuse_map;

  (* Draw the model! *)
  Gl.draw_arrays Gl.triangles 0 (Buffer.length renderable.vbo / 32);

  (* Disable the attributes. *)
  disable_attrib renderable.program "msPosition";
  disable_attrib renderable.program "msNormals";
  disable_attrib renderable.program "texCoords"

let make_particle_system_instance_buffer (camera : Camera.t)
    (particle_system : Particle_system.t) : Buffer.t =
  (* Sort the particles by depth, so transparency works right. *)
  Particle_system.sort_by_distance_from particle_system camera.camera_pos;

  (* Allocate a CPU-side buffer. For now, the only attributes are the position
   * of the particle and its age, so we need four floats per particle.
   *)
  let arr =
    Bigarray.Array1.create Bigarray.Float32 Bigarray.C_layout
      (4 * Particle_system.length particle_system)
  in

  (* Fill in the CPU-side buffer. *)
  Particle_system.iteri
    (fun i p ->
      let x, y, z = p.pos in
      arr.{i * 4} <- x;
      arr.{(i * 4) + 1} <- y;
      arr.{(i * 4) + 2} <- z;
      arr.{(i * 4) + 3} <- p.age)
    particle_system;

  (* Move the buffer to the GPU and return the GPU-side handle. *)
  Buffer.make_static_vbo ~name:"Particle Instance Attributes" ~data:arr

let render_particles (program : Program.t) ~(sphere_vbo : Buffer.t)
    ~(instance_attrs : Buffer.t) ~(view_matrix : Mat4.t) ~(proj_matrix : Mat4.t)
    : unit =
  (* Bind the program. *)
  Gl.use_program (Program.get_handle program);

  (* Bind the view and projection matrices. The model matrix is computed in the vertex shader.*)
  bind_matrix program "view" view_matrix;
  bind_matrix program "proj" proj_matrix;

  (* Bind the sphere VBO, enable its attributes, and set their offsets. *)
  Gl.bind_buffer Gl.array_buffer (Buffer.get_handle sphere_vbo);
  enable_attrib program "msPosition" ~offset:0 ~count:3 ~stride:32;
  enable_attrib program "msNormals" ~offset:12 ~count:3 ~stride:32;
  enable_attrib program "texCoords" ~offset:24 ~count:2 ~stride:32;

  (* Bind the instance attribute VBO, enable its attribute, set its offset, and set it to be instanced. *)
  Gl.bind_buffer Gl.array_buffer (Buffer.get_handle instance_attrs);
  enable_attrib_with_divisor program "wsParticlePos" ~offset:0 ~count:3
    ~stride:16 ~divisor:1;
  enable_attrib_with_divisor program "particleAge" ~offset:12 ~count:1
    ~stride:16 ~divisor:1;

  (* Draw the appropriate number of instances. *)
  Gl.draw_arrays_instanced Gl.triangles 0
    (Buffer.length sphere_vbo / 32)
    (Buffer.length instance_attrs / 16);

  (* Disable the attributes. *)
  disable_attrib program "msPosition";
  disable_attrib program "msNormals";
  disable_attrib program "texCoords";
  disable_attrib program "wsParticlePos";
  disable_attrib program "particleAge"

let render (scene : scene) : unit =
  VAO.bind scene.vao;

  (* Clear the previous frame. *)
  Gl.clear_color 0.0 0.0 0.2 1.0;
  Gl.clear_depth 1.0;
  Gl.clear (Int.logor Gl.color_buffer_bit Gl.depth_buffer_bit);

  (* Render the objects other than the particles. *)
  let view_matrix = Camera.view scene.camera in
  each_renderable
    (fun renderable -> render_one renderable view_matrix scene.proj_matrix)
    scene.opaque_objects;

  (* Create the VBO with the instance attributes for the particle system. *)
  let particle_instance_attrs =
    make_particle_system_instance_buffer scene.camera scene.particle_system
  in

  (* Render the particles. *)
  render_particles scene.particle_program ~sphere_vbo:scene.sphere_vbo
    ~instance_attrs:particle_instance_attrs ~view_matrix
    ~proj_matrix:scene.proj_matrix
