open Tgl3

let find_file : name:string -> ext:string -> string =
  let exe_path = Util.realpath ~path:Sys.argv.(0) in
  let exists ~(path : string) : bool =
    try
      let _ = Unix.stat path in
      true
    with Unix.Unix_error (_, _, _) -> false
  in
  let rec loop ~(base : string) ~(path : string) =
    let full_path = Filename.concat base path in
    if exists ~path:full_path then full_path
    else if base = "/" then raise Not_found
    else loop ~base:(Filename.dirname base) ~path
  in
  fun ~(name : string) ~(ext : string) ->
    let path = "assets/" ^ name ^ "." ^ ext in
    if exists ~path then Util.realpath ~path else loop ~base:exe_path ~path

module type Asset = sig
  type t

  val load : string -> t

  val get_handle : t -> int

  val to_string : t -> string
end

module Shader (Kind : sig
  val id : Gl.enum

  val name : string

  val ext : string
end) : sig
  include Asset

  exception Failed_to_compile_shader of string * string
end = struct
  type t = string * int

  let to_string (name, handle) : string =
    Printf.sprintf "<%s shader %d (%s)>" Kind.name handle name

  let get_handle (_, handle) : int = handle

  exception Failed_to_compile_shader of string * string

  let load (name : string) : t =
    let path = find_file ~name ~ext:Kind.ext in
    let source = Util.read_file_to_string ~path in

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

module Texture : Asset = struct
  type t = string * int

  let to_string (name, handle) : string =
    Printf.sprintf "<texture %d (%s)>" handle name

  let get_handle (_, handle) : int = handle

  let load (name : string) : t =
    let path = find_file ~name ~ext:"png" in
    let image = ImagePNG.parsefile (ImageUtil_unix.chunk_reader_of_path path) in

    let handle = Glutil.get_int (Gl.gen_textures 1) in
    Gl.bind_texture Gl.texture_2d handle;
    (match image.pixels with
    | Image.RGB (Image.Pixmap.Pix8 r, Image.Pixmap.Pix8 g, Image.Pixmap.Pix8 b)
      ->
        let data =
          Bigarray.Array1.create Bigarray.Int8_unsigned Bigarray.C_layout
            (image.width * image.height * 3)
        in
        Util.do_iter image.width (fun x ->
            Util.do_iter image.height (fun y ->
                let i = ((x * image.height) + y) * 3 in
                Bigarray.Array1.set data (i + 0) r.{x, y};
                Bigarray.Array1.set data (i + 1) g.{x, y};
                Bigarray.Array1.set data (i + 2) b.{x, y}));
        Gl.tex_image2d Gl.texture_2d 0 Gl.rgb image.width image.height 0 Gl.rgb
          Gl.unsigned_byte (`Data data)
    | _ -> failwith "unsupported image type");

    let out = (path, handle) in
    Gc.finalise
      (fun texture ->
        Printf.eprintf "freeing %s\n" (to_string texture);
        Glutil.set_int (Gl.delete_textures 1) (get_handle texture))
      out;
    out
end
