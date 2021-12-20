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

let load_objs_to_objects program path model_matrices : node list list =
  let obj_file = Obj_loader.load_file ~path in
  List.map
    (fun model_matrix ->
      List.map
        (fun (_name, meshes) ->
          Nodes
            (List.map
               (fun (material, vbo) ->
                 One { program; vbo; material; model_matrix })
               meshes))
        obj_file)
    model_matrices

let load_objs program path model_matrices : node =
  Nodes
    (List.map
       (fun n -> Nodes n)
       (load_objs_to_objects program path model_matrices))

let load_obj program model_matrix path : node =
  load_objs program path [ model_matrix ]

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
  let frag_default = FragmentShader.load "assets/shaders/default" in
  let frag_ground = FragmentShader.load "assets/shaders/ground" in
  let frag_particle = FragmentShader.load "assets/shaders/particle" in
  let frag_tex_no_lighting =
    FragmentShader.load "assets/shaders/tex_no_lighting"
  in
  let _debug_program = Program.link vert_default frag_debug
  and default_program = Program.link vert_default frag_default
  and ground_program = Program.link vert_default frag_ground
  and particle_program = Program.link vert_particle frag_particle
  and tex_program = Program.link vert_default frag_tex_no_lighting in

  let rec rand v lim =
    let r = Random.float v in
    let x = if r < lim then rand v lim else r in
    if Random.bool () then x *. 1.0 else x *. -1.0
  in

  (* Load the sky *)
  (*let faces = ("right.png", "left.png", "top.png", "bottom.png", "front.png", "back.png")*)

  (* Load the objects. *)
  let campfire =
    load_obj tex_program
      Mat4.(translate ~x:0.0 ~y:0.0 ~z:(-100.0) * scale_uniform 0.01)
      "assets/campfire/OBJ/Campfire.obj"
  and ground =
    load_obj ground_program
      Mat4.(translate ~x:0.0 ~y:0.0 ~z:0.0 * scale_uniform 5000.0)
      "assets/rectangle.obj"
  and mushrooms =
    let get_mushroom (fungi_lists : node list list) : node list list =
      List.map
        (fun lst -> [ List.nth lst (Random.int (List.length lst)) ])
        fungi_lists
    in
    Nodes
      (List.map
         (fun n -> Nodes n)
         (get_mushroom
            (load_objs_to_objects default_program "assets/mushrooms.obj"
               [
                 Mat4.(translate ~x:0.0 ~y:0.0 ~z:0.0 * scale_uniform 1.0);
                 Mat4.(
                   translate ~x:(rand 5.0 1.0) ~y:0.0 ~z:(rand 2.5 1.0)
                   * scale_uniform 1.0);
                 Mat4.(
                   translate ~x:(rand 2.9 1.0) ~y:0.0 ~z:(rand 2.4 1.0)
                   * scale_uniform 1.0);
                 Mat4.(
                   translate ~x:(rand 2.9 1.0) ~y:0.0 ~z:(rand 3.5 1.0)
                   * scale_uniform 1.0);
                 Mat4.(
                   translate ~x:(rand 2.7 1.0) ~y:0.0 ~z:(rand 2.5 1.0)
                   * scale_uniform 1.0);
               ])))
  and trees =
    let rec scale_tree v =
      let r = Random.float v in
      if r < 0.003 then scale_tree v else r
    in
    let rec place_trees n (lst : Mat4.t list) =
      match n with
      | 0 -> lst
      | _ ->
          place_trees (n - 1)
            (Mat4.(
               translate ~x:(rand 4000.0 400.0) ~y:(-50.0)
                 ~z:(rand 4000.0 400.0)
               * scale_uniform (scale_tree 0.05))
            :: lst)
    in
    load_objs default_program
      "assets/conifer_macedonian_pine/conifer_macedonian_pine.obj"
      ([
         Mat4.(translate ~x:25.0 ~y:(-50.0) ~z:(-1000.0) * scale_uniform 0.005);
         Mat4.(
           translate ~x:(-400.0) ~y:(-50.0) ~z:(-2000.0) * scale_uniform 0.007);
         Mat4.(translate ~x:700.0 ~y:(-50.0) ~z:(-50.0) * scale_uniform 0.01);
         Mat4.(translate ~x:300.0 ~y:(-50.0) ~z:2000.0 * scale_uniform 0.008);
         Mat4.(translate ~x:(-800.0) ~y:(-50.0) ~z:1500.0 * scale_uniform 0.02);
         Mat4.(translate ~x:(-300.0) ~y:(-50.0) ~z:40.0 * scale_uniform 0.005);
       ]
      @ place_trees 50 [])
  in
  (* Load the sphere model. *)
  let sphere_vbo =
    Obj_loader.load_file ~path:"assets/sphere.obj"
    |> List.hd |> snd |> List.hd |> snd
  in

  (* Make and bind the VAO. *)
  let vao = VAO.make () in
  VAO.bind vao;

  (* Enable the depth test. *)
  Gl.enable Gl.depth_test;
  Gl.depth_func Gl.less;

  (* Enable transparent objects. *)
  Gl.enable Gl.blend;

  (* Enable MSAA. *)
  Gl.enable Gl.multisample;

  (* Enable face culling. *)
  Gl.enable Gl.cull_face_enum;
  Gl.cull_face Gl.back;

  (* Make the scene. *)
  {
    vao;
    particle_system;
    sphere_vbo;
    particle_program;
    opaque_objects = Nodes [ campfire; ground; mushrooms; trees ];
    camera;
    proj_matrix =
      Mat4.perspective ~fovy:(Float.pi /. 2.0) ~aspect:(16.0 /. 9.0) ~near:0.01
        ~far:1000.0;
  }

let bind_float (program : Program.t) (name : string) : float -> unit =
  let location = Gl.get_uniform_location (Program.get_handle program) name in
  Gl.uniform1f location

let bind_matrix (program : Program.t) (name : string) : Mat4.t -> unit =
  let location = Gl.get_uniform_location (Program.get_handle program) name in
  Gl.uniform_matrix4fv location 1 false % Mat4.to_bigarray

let bind_tex_opt (program : Program.t) (texture_enum : Gl.enum)
    (texture_idx : int) ~(name_tex : string) ~(name_has : string) :
    Texture.t option -> unit =
  let get_location = Gl.get_uniform_location (Program.get_handle program) in
  let location_tex = get_location name_tex
  and location_has = get_location name_has in
  function
  | Some texture ->
      Gl.active_texture texture_enum;
      Gl.bind_texture Gl.texture_2d (Texture.get_handle texture);
      Gl.uniform1i location_tex texture_idx;
      Gl.uniform1i location_has 1
  | None -> Gl.uniform1i location_has 0

let bind_vec3 (program : Program.t) (name : string) : Vec3.t -> unit =
  let location = Gl.get_uniform_location (Program.get_handle program) name in
  fun (x, y, z) -> Gl.uniform3f location x y z

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

let make_lighting_ubo (particle_system : Particle_system.t) : Buffer.t * int =
  let arr = Bigarray.Array1.create Bigarray.Float32 Bigarray.C_layout 1024
  and particles = Particle_system.get_lighting_particles particle_system in
  DynArr.iteri
    (fun i p ->
      if i < 126 then (
        let open Particle in
        let x, y, z = p.pos and intensity = 1.0 and r, g, b = (1.0, 1.0, 1.0) in
        arr.{i * 8} <- x;
        arr.{(i * 8) + 1} <- y;
        arr.{(i * 8) + 2} <- z;
        arr.{(i * 8) + 3} <- intensity;
        arr.{(i * 8) + 4} <- r;
        arr.{(i * 8) + 5} <- g;
        arr.{(i * 8) + 6} <- b;
        arr.{(i * 8) + 7} <- 0.0))
    particles;
  (Buffer.make_ubo ~name:"Lighting UBO" ~data:arr, DynArr.length particles)

let make_model_matrix_vbo (model_matrices : Mat4.t DynArr.t) : Buffer.t =
  let data =
    Bigarray.Array1.create Bigarray.Float32 Bigarray.C_layout
      (16 * DynArr.length model_matrices)
  in
  DynArr.iteri
    (fun i
         ( (x11, x12, x13, x14),
           (x21, x22, x23, x24),
           (x31, x32, x33, x34),
           (x41, x42, x43, x44) ) ->
      data.{i * 16} <- x11;
      data.{(i * 16) + 1} <- x12;
      data.{(i * 16) + 2} <- x13;
      data.{(i * 16) + 3} <- x14;
      data.{(i * 16) + 4} <- x21;
      data.{(i * 16) + 5} <- x22;
      data.{(i * 16) + 6} <- x23;
      data.{(i * 16) + 7} <- x24;
      data.{(i * 16) + 8} <- x31;
      data.{(i * 16) + 9} <- x32;
      data.{(i * 16) + 10} <- x33;
      data.{(i * 16) + 11} <- x34;
      data.{(i * 16) + 12} <- x41;
      data.{(i * 16) + 13} <- x42;
      data.{(i * 16) + 14} <- x43;
      data.{(i * 16) + 15} <- x44)
    model_matrices;
  Buffer.make_static_vbo ~name:"Model Matrix VBO" ~data

let render_one ~(program : Program.t) ~(vbo : Buffer.t)
    ~(material : Mtl_loader.mat) ~(model_matrices : Mat4.t DynArr.t)
    ~(lighting_ubo : Buffer.t) ~(light_count : int) ~(view_matrix : Mat4.t)
    ~(proj_matrix : Mat4.t) : unit =
  (* Bind the program. *)
  Gl.use_program (Program.get_handle program);
  (* Bind the view and projection matrices. *)
  bind_matrix program "view" view_matrix;
  bind_matrix program "proj" proj_matrix;

  (* Bind the VBO. *)
  Gl.bind_buffer Gl.array_buffer (Buffer.get_handle vbo);
  (* Enable the attributes and set their offsets. *)
  let stride = 32 in
  enable_attrib program "msPosition" ~offset:0 ~count:3 ~stride;
  enable_attrib program "msNormals" ~offset:12 ~count:3 ~stride;
  enable_attrib program "texCoords" ~offset:24 ~count:2 ~stride;

  (* Create and bind the model matrix VBO. *)
  let model_matrix_vbo = make_model_matrix_vbo model_matrices in
  Gl.bind_buffer Gl.array_buffer (Buffer.get_handle model_matrix_vbo);

  (let index = Gl.get_attrib_location (Program.get_handle program) "model" in
   Gl.enable_vertex_attrib_array index;
   Gl.vertex_attrib_pointer index 4 Gl.float false 64 (`Offset 0);
   Gl.vertex_attrib_divisor index 1;
   Gl.enable_vertex_attrib_array (index + 1);
   Gl.vertex_attrib_pointer (index + 1) 4 Gl.float false 64 (`Offset 16);
   Gl.vertex_attrib_divisor (index + 1) 1;
   Gl.enable_vertex_attrib_array (index + 2);
   Gl.vertex_attrib_pointer (index + 2) 4 Gl.float false 64 (`Offset 32);
   Gl.vertex_attrib_divisor (index + 2) 1;
   Gl.enable_vertex_attrib_array (index + 3);
   Gl.vertex_attrib_pointer (index + 3) 4 Gl.float false 64 (`Offset 48);
   Gl.vertex_attrib_divisor (index + 3) 1);

  (* Bind the UBO and bind it to the appropriate block. *)
  Gl.bind_buffer Gl.uniform_buffer (Buffer.get_handle lighting_ubo);
  Gl.uniform_block_binding
    (Program.get_handle program)
    (Gl.get_uniform_block_index (Program.get_handle program) "light_ubo")
    0;
  Gl.bind_buffer_range Gl.uniform_buffer 0
    (Buffer.get_handle lighting_ubo)
    0
    (Buffer.length lighting_ubo);
  Printf.printf "light_count = %d\n" light_count;
  Gl.uniform1i
    (Gl.get_uniform_location (Program.get_handle program) "lightCount")
    light_count;

  (* Bind the texture, if there is one. *)
  bind_tex_opt program Gl.texture0 0 ~name_tex:"diffuseTex"
    ~name_has:"hasDiffuseTex" material.diffuse_map;

  (* Bind the other material parameters. *)
  bind_vec3 program "materialAmbient" material.ambient;
  bind_vec3 program "materialDiffuse" material.diffuse;
  bind_vec3 program "materialSpecular" material.specular;
  bind_float program "specularExponent" material.specular_exponent;

  (* Draw the model! *)
  Gl.draw_arrays_instanced Gl.triangles 0
    (Buffer.length vbo / 32)
    (DynArr.length model_matrices);

  (* Keep the VBO alive till here. *)
  Buffer.free model_matrix_vbo;

  (* Disable the attributes. *)
  disable_attrib program "msPosition";
  disable_attrib program "msNormals";
  disable_attrib program "texCoords"

let make_particle_system_instance_buffer (camera : Camera.t)
    (particle_system : Particle_system.t) : Buffer.t =
  (* Sort the visible particles by depth, so transparency works right. *)
  Particle_system.sort_visible_by_distance_from particle_system
    camera.camera_pos;

  (* Allocate a CPU-side buffer. For now, the only attributes are the position
   * of the particle and its age, so we need four floats per particle.
   *)
  let visible_particles =
    Particle_system.get_visible_particles particle_system
  in
  let arr =
    Bigarray.Array1.create Bigarray.Float32 Bigarray.C_layout
      (4 * DynArr.length visible_particles)
  in

  (* Fill in the CPU-side buffer. *)
  DynArr.iteri
    (fun i p ->
      let open Particle in
      let x, y, z = p.pos in
      arr.{i * 4} <- x;
      arr.{(i * 4) + 1} <- y;
      arr.{(i * 4) + 2} <- z;
      arr.{(i * 4) + 3} <- p.age)
    visible_particles;

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

module InstanceMap = Map.Make (struct
  type t = Program.t * Buffer.t * Mtl_loader.mat

  let compare = compare
end)

let collect_instances (root : node) : Mat4.t DynArr.t InstanceMap.t =
  let map = ref InstanceMap.empty in
  each_renderable
    (fun renderable ->
      map :=
        InstanceMap.update
          (renderable.program, renderable.vbo, renderable.material)
          (fun old ->
            let old =
              match old with Some arr -> arr | None -> DynArr.make ~capacity:1
            in
            DynArr.push old renderable.model_matrix;
            Some old)
          !map)
    root;
  !map

let render (scene : scene) : unit =
  VAO.bind scene.vao;

  (* Clear the previous frame. *)
  Gl.clear_color 0.01 0.0 0.1 1.0;
  Gl.clear_depth 1.0;
  Gl.clear (Int.logor Gl.color_buffer_bit Gl.depth_buffer_bit);

  (* Render the objects other than the particles. *)
  Gl.blend_func Gl.one Gl.zero;
  let lighting_ubo, light_count = make_lighting_ubo scene.particle_system
  and view_matrix = Camera.view scene.camera in
  collect_instances scene.opaque_objects
  |> InstanceMap.to_seq
  |> Seq.iter (fun ((program, vbo, material), model_matrices) ->
         render_one ~program ~vbo ~material ~model_matrices ~lighting_ubo
           ~light_count ~view_matrix ~proj_matrix:scene.proj_matrix);
  Buffer.free lighting_ubo;

  (* Create the VBO with the instance attributes for the particle system. *)
  let particle_instance_attrs =
    make_particle_system_instance_buffer scene.camera scene.particle_system
  in

  (* Render the particles. *)
  Gl.blend_func Gl.src_alpha Gl.one_minus_src_alpha;
  render_particles scene.particle_program ~sphere_vbo:scene.sphere_vbo
    ~instance_attrs:particle_instance_attrs ~view_matrix
    ~proj_matrix:scene.proj_matrix;
  Buffer.free particle_instance_attrs
