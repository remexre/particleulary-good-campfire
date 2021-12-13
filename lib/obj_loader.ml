open Util

type face_elem = { vertex : int; texcoord : int option; normal : int option }

let string_of_face_elem { vertex; texcoord; normal } =
  let string_of_int_option = function
    | Some i -> Printf.sprintf "Some %d" i
    | None -> "None"
  in
  Printf.sprintf "{ vertex = %d; texcoord = %s; normal = %s }" vertex
    (string_of_int_option texcoord)
    (string_of_int_option normal)

type obj_directive =
  | Name of string
  | Vertex of float * float * float
  | Texcoord of float * float * float option
  | Normal of float * float * float
  | Face of face_elem list
  | SmoothShading of int option
  | MTLLib of string
  | UseMTL of string

let string_of_obj_directive = function
  | Name s -> Printf.sprintf "Name %S" s
  | Vertex (x, y, z) -> Printf.sprintf "Vertex (%f, %f, %f)" x y z
  | Texcoord (s, t, Some p) -> Printf.sprintf "Texcoord (%f, %f, Some %f)" s t p
  | Texcoord (s, t, None) -> Printf.sprintf "Texcoord (%f, %f, None)" s t
  | Normal (x, y, z) -> Printf.sprintf "Normal (%f, %f, %f)" x y z
  | Face elems ->
      Printf.sprintf "Face [%s]"
        (String.concat "; " (List.map string_of_face_elem elems))
  | SmoothShading (Some group) -> Printf.sprintf "SmoothShading (Some %d)" group
  | SmoothShading None -> "SmoothShading None"
  | MTLLib s -> Printf.sprintf "MTLLib %S" s
  | UseMTL s -> Printf.sprintf "UseMTL %S" s

let parse_face_elem elem =
  match String.split_on_char '/' elem with
  | [ vertex ] ->
      Some { vertex = int_of_string vertex; texcoord = None; normal = None }
  | [ vertex; texcoord ] ->
      Some
        {
          vertex = int_of_string vertex;
          texcoord = Some (int_of_string texcoord);
          normal = None;
        }
  | [ vertex; texcoord; normal ] ->
      Some
        {
          vertex = int_of_string vertex;
          texcoord = Some (int_of_string texcoord);
          normal = Some (int_of_string normal);
        }
  | _ -> None

let parse_obj_directive line =
  let inner chunks =
    try
      match chunks with
      | "f" :: elems -> (
          match mapM_option parse_face_elem elems with
          | Some elems -> Some (Face elems)
          | _ -> failf "Unsupported face %S" line)
      | [ "mtllib"; path ] -> Some (MTLLib path)
      | [ "usemtl"; path ] -> Some (UseMTL path)
      | [ "s"; "off" ] -> Some (SmoothShading None)
      | [ "s"; group ] -> Some (SmoothShading (Some (int_of_string group)))
      | [ "v"; x; y; z ] ->
          Some
            (Vertex (Float.of_string x, Float.of_string y, Float.of_string z))
      | [ "vn"; x; y; z ] ->
          Some
            (Normal (Float.of_string x, Float.of_string y, Float.of_string z))
      | [ "vt"; s; t ] ->
          Some (Texcoord (Float.of_string s, Float.of_string t, None))
      | [ "vt"; s; t; p ] ->
          Some
            (Texcoord
               (Float.of_string s, Float.of_string t, Some (Float.of_string p)))
      | "g" :: _ -> None
      | "o" :: _ -> None
      | _ -> failf "Unknown OBJ directive %S" line
    with exc ->
      failf "Failed to parse OBJ directive %S: %s" line (Printexc.to_string exc)
  in
  inner

let load_file (path : string) =
  Util.read_file_to_string ~path
  |> String.split_on_char '\n' |> List.to_seq
  |> Seq.map (List.hd % String.split_on_char '#')
  |> Seq.map String.trim
  |> Seq.filter (( <> ) "")
  |> Seq.filter_map (fun line ->
         String.split_on_char ' ' line
         |> List.filter (( <> ) "")
         |> parse_obj_directive line)
  |> Seq.map string_of_obj_directive
  |> List.of_seq |> String.concat "; " |> Printf.printf "[%s]\n"
