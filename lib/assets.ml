open Tgl3
open Util

let find_file : string -> string =
  let exe_path = realpath ~path:Sys.argv.(0) in
  let exists ~(path : string) : bool =
    try
      let _ = Unix.stat path in
      true
    with Unix.Unix_error (_, _, _) -> false
  in
  let rec loop ~(base : string) ~(path : string) =
    let full_path = Filename.concat base path in
    if exists ~path:full_path then full_path
    else if base = "/" then failf "Couldn't find %s" path
    else loop ~base:(Filename.dirname base) ~path
  in
  fun path -> if exists ~path then realpath ~path else loop ~base:exe_path ~path

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

module Shader (Kind : sig
  val id : Gl.enum

  val name : string

  val ext : string
end) : sig
  include Asset

  include OpenGLResource with type t := t

  exception Failed_to_compile_shader of string * string
end = struct
  type t = string * int

  let to_string (name, handle) : string =
    Printf.sprintf "<%s shader %d (%s)>" Kind.name handle name

  let get_handle (_, handle) : int = handle

  exception Failed_to_compile_shader of string * string

  let load (name : string) : t =
    let path = find_file (name ^ "." ^ Kind.ext) in
    let source = read_file_to_string ~path in

    let handle = Gl.create_shader Kind.id in
    Gl.shader_source handle source;
    Gl.compile_shader handle;

    let get_shader (param : int) : int =
      Glutil.get_int (Gl.get_shaderiv handle param)
    in

    if get_shader Gl.compile_status <> Gl.true_ then (
      let info_log_len = get_shader Gl.info_log_length in
      let info_log =
        Bigarray.Array1.create Bigarray.Char Bigarray.C_layout info_log_len
      in
      Gl.get_shader_info_log handle info_log_len None info_log;
      let shader_log = Gl.string_of_bigarray info_log in
      Gl.delete_shader handle;
      raise (Failed_to_compile_shader (path, shader_log)))
    else
      let out = (path, handle) in
      Gc.finalise
        (fun shader ->
          Printf.eprintf "freeing %s\n" (to_string shader);
          Gl.delete_shader (get_handle shader))
        out;
      out
end

module VertexShader = Shader (struct
  let id = Gl.vertex_shader

  let name = "vertex"

  let ext = "vert"
end)

module FragmentShader = Shader (struct
  let id = Gl.fragment_shader

  let name = "fragment"

  let ext = "frag"
end)

module Program : sig
  include Asset

  include OpenGLResource with type t := t

  exception Failed_to_link_shader_program of string * string * string

  val link : VertexShader.t -> FragmentShader.t -> t
end = struct
  type t = string * string * int

  let to_string (vertex_shader, fragment_shader, handle) : string =
    Printf.sprintf "<program %d %s %s>" handle vertex_shader fragment_shader

  let get_handle (_, _, handle) : int = handle

  exception Failed_to_link_shader_program of string * string * string

  let link (vert : VertexShader.t) (frag : FragmentShader.t) : t =
    let handle = Gl.create_program () in
    Gl.attach_shader handle (VertexShader.get_handle vert);
    Gl.attach_shader handle (FragmentShader.get_handle frag);
    Gl.link_program handle;

    let get_program (param : int) : int =
      Glutil.get_int (Gl.get_programiv handle param)
    in

    if get_program Gl.link_status <> Gl.true_ then (
      let info_log_len = get_program Gl.info_log_length in
      let info_log =
        Bigarray.Array1.create Bigarray.Char Bigarray.C_layout info_log_len
      in
      Gl.get_program_info_log handle info_log_len None info_log;
      let program_log = Gl.string_of_bigarray info_log in
      Gl.delete_program handle;
      raise
        (Failed_to_link_shader_program
           ( VertexShader.to_string vert,
             FragmentShader.to_string frag,
             program_log )))
    else
      let out =
        (VertexShader.to_string vert, FragmentShader.to_string frag, handle)
      in
      Gc.finalise
        (fun program ->
          Printf.eprintf "freeing %s\n" (to_string program);
          Gl.delete_program (get_handle program))
        out;
      out

  let load (name : string) : t =
    let vert = VertexShader.load name in
    let frag = FragmentShader.load name in
    link vert frag
end

module Texture : sig
  include Asset

  include OpenGLResource with type t := t
end = struct
  type t = string * int

  let to_string (name, handle) : string =
    Printf.sprintf "<texture %d (%s)>" handle name

  let get_handle (_, handle) : int = handle

  let load (name : string) : t =
    let path = find_file name in
    let image =
      ImageLib.openfile
        ~extension:(string_tail (Filename.extension name))
        (ImageUtil_unix.chunk_reader_of_path path)
    in

    let handle = Glutil.get_int (Gl.gen_textures 1) in
    Gl.bind_texture Gl.texture_2d handle;
    (match image.pixels with
    | Image.RGB (Image.Pixmap.Pix8 r, Image.Pixmap.Pix8 g, Image.Pixmap.Pix8 b)
      ->
        let data =
          Bigarray.Array1.create Bigarray.Int8_unsigned Bigarray.C_layout
            (image.width * image.height * 3)
        in
        dotimes image.width (fun x ->
            dotimes image.height (fun y ->
                let i = ((x * image.height) + y) * 3 in
                Bigarray.Array1.set data (i + 0) r.{x, y};
                Bigarray.Array1.set data (i + 1) g.{x, y};
                Bigarray.Array1.set data (i + 2) b.{x, y}));
        Gl.tex_image2d Gl.texture_2d 0 Gl.rgb image.width image.height 0 Gl.rgb
          Gl.unsigned_byte (`Data data);
        Gl.generate_mipmap Gl.texture_2d
    | Image.RGBA
        ( Image.Pixmap.Pix8 r,
          Image.Pixmap.Pix8 g,
          Image.Pixmap.Pix8 b,
          Image.Pixmap.Pix8 a ) ->
        let data =
          Bigarray.Array1.create Bigarray.Int8_unsigned Bigarray.C_layout
            (image.width * image.height * 4)
        in
        dotimes image.width (fun x ->
            dotimes image.height (fun y ->
                let i = ((x * image.height) + y) * 4 in
                Bigarray.Array1.set data (i + 0) r.{x, y};
                Bigarray.Array1.set data (i + 1) g.{x, y};
                Bigarray.Array1.set data (i + 2) b.{x, y};
                Bigarray.Array1.set data (i + 3) a.{x, y}));
        Gl.tex_image2d Gl.texture_2d 0 Gl.rgba image.width image.height 0 Gl.rgb
          Gl.unsigned_byte (`Data data);
        Gl.generate_mipmap Gl.texture_2d
    | _ -> failwith "unsupported image type");

    let out = (path, handle) in
    Gc.finalise
      (fun texture ->
        Printf.eprintf "freeing %s\n" (to_string texture);
        Glutil.set_int (Gl.delete_textures 1) (get_handle texture))
      out;
    out
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

  val length : t -> int
end = struct
  type t = {
    kind : string;
    name : string;
    usage : Gl.enum;
    size : int;
    handle : int;
  }

  type float_array =
    (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t

  let to_string { kind; name; handle; _ } : string =
    Printf.sprintf "<%s buffer %d (%s)>" kind handle name

  let get_handle { handle; _ } : int = handle

  let make_uninit ~(kind : string) ~(name : string) ~(target : Gl.enum)
      ~(usage : Gl.enum) ~(size : int) : t =
    let handle = Glutil.get_int (Gl.gen_buffers 1) in
    Gl.bind_buffer target handle;
    Gl.buffer_data target size None usage;

    let out = { kind; name; usage; size; handle } in
    Gc.finalise
      (fun buffer ->
        Printf.eprintf "freeing %s\n" (to_string buffer);
        Glutil.set_int (Gl.delete_buffers 1) (get_handle buffer))
      out;
    out

  let make_static_vbo ~(name : string) ~(data : float_array) : t =
    let size = 4 * Bigarray.Array1.dim data and target = Gl.array_buffer in
    let buffer =
      make_uninit ~kind:"vertex" ~name ~target ~usage:Gl.static_draw ~size
    in
    Gl.bind_buffer target (get_handle buffer);
    Gl.buffer_data target size (Some data) Gl.static_draw;
    buffer

  let make_ubo ~(name : string) ~(data : float_array) : t =
    let size = 4 * Bigarray.Array1.dim data and target = Gl.uniform_buffer in
    let buffer =
      make_uninit ~kind:"uniform" ~name ~target ~usage:Gl.static_draw ~size
    in
    Gl.bind_buffer target (get_handle buffer);
    Gl.buffer_data target size (Some data) Gl.static_draw;
    buffer

  let length { size; _ } = size
end

module VAO : sig
  include OpenGLResource

  val make : unit -> t

  val bind : t -> unit
end = struct
  type t = { handle : int }

  let to_string { handle } : string = Printf.sprintf "<VAO %d>" handle

  let get_handle { handle } : int = handle

  let make () : t =
    let handle = Glutil.get_int (Gl.gen_vertex_arrays 1) in

    let out = { handle } in
    Gc.finalise
      (fun vao ->
        Printf.eprintf "freeing %s\n" (to_string vao);
        Glutil.set_int (Gl.delete_vertex_arrays 1) (get_handle vao))
      out;
    out

  let bind { handle } = Gl.bind_vertex_array handle
end
