open Util

type face_indices = {
  position : int;
  texcoord : int option;
  normal : int option;
}

type vec2 = float * float

type obj_directive =
  | Position of Vec3.t
  | Texcoord of vec2
  | Normal of Vec3.t
  | Face of face_indices list
  | SmoothShading of int option

let parse_face_indices elem =
  match String.split_on_char '/' elem with
  | [ position ] ->
      Some { position = int_of_string position; texcoord = None; normal = None }
  | [ position; texcoord ] ->
      Some
        {
          position = int_of_string position;
          texcoord = Some (int_of_string texcoord);
          normal = None;
        }
  | [ position; texcoord; normal ] ->
      Some
        {
          position = int_of_string position;
          texcoord = Some (int_of_string texcoord);
          normal = Some (int_of_string normal);
        }
  | _ -> None

let parse_obj_directive line =
  let inner chunks =
    try
      match chunks with
      | "f" :: elems -> (
          match mapM_option parse_face_indices elems with
          | Some elems -> Some (Face elems)
          | _ -> failf "Unsupported face %S" line)
      | [ "s"; "off" ] -> Some (SmoothShading None)
      | [ "s"; group ] -> Some (SmoothShading (Some (int_of_string group)))
      | [ "v"; x; y; z ] ->
          Some
            (Position (Float.of_string x, Float.of_string y, Float.of_string z))
      | [ "vn"; x; y; z ] ->
          Some
            (Normal (Float.of_string x, Float.of_string y, Float.of_string z))
      | [ "vt"; s; t ] -> Some (Texcoord (Float.of_string s, Float.of_string t))
      | ("g" | "o" | "mtllib" | "usemtl") :: _ -> None
      | _ -> failf "Unknown OBJ directive %S" line
    with exc ->
      failf "Failed to parse OBJ directive %S: %s" line (Printexc.to_string exc)
  in
  inner

let obj_directives_of_string src =
  String.split_on_char '\n' src
  |> List.to_seq
  |> Seq.map (List.hd % String.split_on_char '#')
  |> Seq.map String.trim
  |> Seq.filter (( <> ) "")
  |> Seq.filter_map (fun line ->
         String.split_on_char ' ' line
         |> List.filter (( <> ) "")
         |> parse_obj_directive line)

module GroupMap = Map.Make (struct
  type t = int option

  let compare = compare
end)

let separate_groups (groups : 'a list GroupMap.t) : 'a list Seq.t =
  let lift_fst = function Some l, r -> Some (l, r) | None, _ -> None in
  let explicit_groups =
    GroupMap.to_seq groups |> Seq.filter_map lift_fst
    |> Seq.filter (( <> ) [] % snd)
    |> Seq.map snd
  and implicit_groups =
    GroupMap.find_opt None groups
    |> Option.value ~default:[] |> List.to_seq
    |> Seq.map (fun x -> [ x ])
  in
  Seq.append explicit_groups implicit_groups

let update_smoothing_group (group : int option)
    ((smoothing_groups, current_group, current_group_index) :
      'a list GroupMap.t * 'a list * int option) :
    'a list GroupMap.t * 'a list * int option =
  ( GroupMap.update current_group_index
      (Option.some % List.rev_append current_group % Option.value ~default:[])
      smoothing_groups,
    [],
    group )

type face_elem_with_optional_normals = {
  position : Vec3.t;
  texcoord : vec2 option;
  normal : Vec3.t option;
}

let index_face_elem (positions : Vec3.t array) (texcoords : vec2 array)
    (normals : Vec3.t array) ({ position; texcoord; normal } : face_indices) :
    face_elem_with_optional_normals =
  let dec i = i - 1 in
  let get_opt arr i = if i >= Array.length arr then None else Some arr.(i) in
  {
    position = positions.(position - 1);
    texcoord = Option.bind texcoord (get_opt texcoords % dec);
    normal = Option.map (Array.get normals % dec) normal;
  }

type face_with_optional_normals = {
  positions : Vec3.t * Vec3.t * Vec3.t;
  texcoords : (vec2 * vec2 * vec2) option;
  normals : (Vec3.t * Vec3.t * Vec3.t) option;
}

let rec split_to_tris :
    face_elem_with_optional_normals list -> face_with_optional_normals list =
  function
  | [ v1; v2; v3 ] ->
      let texcoords =
        match (v1.texcoord, v2.texcoord, v3.texcoord) with
        | Some t1, Some t2, Some t3 -> Some (t1, t2, t3)
        | _ -> None
      and normals =
        match (v1.normal, v2.normal, v3.normal) with
        | Some n1, Some n2, Some n3 -> Some (n1, n2, n3)
        | _ -> None
      in
      [
        {
          positions = (v1.position, v2.position, v3.position);
          texcoords;
          normals;
        };
      ]
  | [ v1; v2; v3; v4 ] ->
      split_to_tris [ v1; v2; v3 ] @ split_to_tris [ v3; v4; v1 ]
  | l -> failf "invalid face (%d sides)" (List.length l)

type face_with_optional_texcoords = {
  positions : Vec3.t * Vec3.t * Vec3.t;
  texcoords : (vec2 * vec2 * vec2) option;
  normals : Vec3.t * Vec3.t * Vec3.t;
}

module Vec3Map = Map.Make (struct
  type t = Vec3.t

  let compare = compare
end)

let compute_face_normal (v1 : Vec3.t) (v2 : Vec3.t) (v3 : Vec3.t) : Vec3.t =
  Vec3.(cross (v1 - v2) (v1 - v3))

let compute_normals
    (faces :
      ((Vec3.t * Vec3.t * Vec3.t)
      * (Vec3.t * Vec3.t * Vec3.t -> face_with_optional_texcoords))
      list) : face_with_optional_texcoords list =
  let add_normal pos normal =
    Vec3Map.update pos (fun old ->
        Some (normal :: Option.value old ~default:[]))
  in
  let face_normals =
    List.fold_left
      (flip (fun ((p1, p2, p3), _) ->
           let normal = compute_face_normal p1 p2 p3 in
           add_normal p1 normal % add_normal p2 normal % add_normal p3 normal))
      Vec3Map.empty faces
    |> Vec3Map.map (Vec3.normalize % List.fold_left Vec3.( + ) Vec3.zero)
  in
  List.map
    (fun ((p1, p2, p3), make_face) ->
      make_face
        ( Vec3Map.find p1 face_normals,
          Vec3Map.find p2 face_normals,
          Vec3Map.find p3 face_normals ))
    faces

let compute_normals_if_needed (faces : face_with_optional_normals list) :
    face_with_optional_texcoords list =
  let faces_with_normals, faces_without_normals =
    List.partition_map
      (fun ({ positions; texcoords; normals } : face_with_optional_normals) ->
        match normals with
        | Some normals -> Left { positions; texcoords; normals }
        | None ->
            Right (positions, fun normals -> { positions; texcoords; normals }))
      faces
  in
  let faces_with_normals_empty = faces_with_normals = []
  and faces_without_normals_empty = faces_without_normals = [] in
  match (faces_with_normals_empty, faces_without_normals_empty) with
  | true, true -> []
  | true, false -> compute_normals faces_without_normals
  | false, true -> faces_with_normals
  | false, false -> failwith "smoothing group with partial normals"

type face = {
  positions : Vec3.t * Vec3.t * Vec3.t;
  texcoords : vec2 * vec2 * vec2;
  normals : Vec3.t * Vec3.t * Vec3.t;
}

let insert_texcoords_if_needed (faces : face_with_optional_texcoords Seq.t) :
    face array =
  let insert_texcoords_if_needed_1
      ({ positions; texcoords; normals } : face_with_optional_texcoords) =
    match texcoords with
    | Some texcoords -> { positions; texcoords; normals }
    | None ->
        { positions; texcoords = ((0.0, 0.0), (0.0, 0.0), (0.0, 0.0)); normals }
  in
  Array.of_seq (Seq.map insert_texcoords_if_needed_1 faces)

let faces_of_string src =
  let directives = obj_directives_of_string src in
  let extract_directives f = directives |> Seq.filter_map f |> Array.of_seq in
  (* TODO: It should be possible to do one traversal instead of four. *)
  let positions =
    extract_directives (function
      | Position (x, y, z) -> Some (x, y, z)
      | _ -> None)
  and texcoords =
    extract_directives (function Texcoord (u, v) -> Some (u, v) | _ -> None)
  and normals =
    extract_directives (function
      | Normal (x, y, z) -> Some (x, y, z)
      | _ -> None)
  in
  let get_smoothing_groups (smoothing_groups, _, _) = smoothing_groups in
  directives
  |> Seq.filter_map (function
       | Face faces ->
           Some
             (`Face
               (List.map (index_face_elem positions texcoords normals) faces))
       | SmoothShading group -> Some (`SmoothShading group)
       | _ -> None)
  |> Seq.fold_left
       (fun (smoothing_groups, current_group, current_group_index) -> function
         | `Face face ->
             ( smoothing_groups,
               split_to_tris face @ current_group,
               current_group_index )
         | `SmoothShading group ->
             update_smoothing_group group
               (smoothing_groups, current_group, current_group_index))
       (GroupMap.empty, [], None)
  |> update_smoothing_group None
  |> get_smoothing_groups |> separate_groups
  |> Seq.map compute_normals_if_needed
  |> Seq.flat_map List.to_seq |> insert_texcoords_if_needed

let load_file ~(path : string) =
  let faces = faces_of_string (Util.read_file_to_string ~path) in
  Array.to_seq faces
  |> Seq.flat_map
       (fun
         {
           positions = p1, p2, p3;
           texcoords = t1, t2, t3;
           normals = n1, n2, n3;
         }
       -> List.to_seq [ (p1, t1, n1); (p2, t2, n2); (p3, t3, n3) ])
  |> Seq.flat_map (fun ((px, py, pz), (tu, tv), (nx, ny, nz)) ->
         List.to_seq [ px; py; pz; nx; ny; nz; tu; tv ])
  |> Array.of_seq
  |> Bigarray.Array1.of_array Bigarray.Float32 Bigarray.C_layout
  |> fun data -> Assets.Buffer.make_static_vbo ~name:path ~data
