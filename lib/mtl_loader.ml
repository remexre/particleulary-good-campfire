open Util

type illumination_model = Highlight | TransparencyAndRayTracedReflections

type mtl_directive =
  | NewMTL of string
  | Illum of illumination_model
  | AmbientColor of Vec3.t
  | DiffuseColor of Vec3.t
  | SpecularColor of Vec3.t
  | SpecularExponent of float
  | Dissolve of float
  | TransmissionFilter of Vec3.t
  | IndexOfRefraction of float
  | MapDiffuseColor of string
  | EmissiveColor of Vec3.t

let parse_mtl_directive line =
  let inner chunks =
    try
      match chunks with
      | [ "newmtl"; name ] -> NewMTL name
      | [ "illum"; "2" ] -> Illum Highlight
      | [ "illum"; "4" ] -> Illum TransparencyAndRayTracedReflections
      | [ "Ka"; r; g; b ] ->
          AmbientColor (Float.of_string r, Float.of_string g, Float.of_string b)
      | [ "Kd"; r; g; b ] ->
          DiffuseColor (Float.of_string r, Float.of_string g, Float.of_string b)
      | [ "Ks"; r; g; b ] ->
          SpecularColor (Float.of_string r, Float.of_string g, Float.of_string b)
      | [ "Ns"; k ] -> SpecularExponent (Float.of_string k)
      | [ "d"; d ] -> Dissolve (Float.of_string d)
      | [ "Tf"; x; y; z ] ->
          TransmissionFilter
            (Float.of_string x, Float.of_string y, Float.of_string z)
      | [ "Ni"; ior ] -> IndexOfRefraction (Float.of_string ior)
      | [ "map_Kd"; path ] -> MapDiffuseColor path
      | [ "Ke"; r; g; b ] ->
          EmissiveColor (Float.of_string r, Float.of_string g, Float.of_string b)
      | _ -> failf "Unknown MTL directive %S" line
    with exc ->
      failf "Failed to parse MTL directive %S: %s" line (Printexc.to_string exc)
  in
  inner

let load_file ~(path : string) : unit =
  read_file_to_string ~path |> String.split_on_char '\n' |> List.to_seq
  |> Seq.map (List.hd % String.split_on_char '#')
  |> Seq.map String.trim
  |> Seq.filter (( <> ) "")
  |> Seq.map (fun line ->
         String.split_on_char ' ' line
         |> List.filter (( <> ) "")
         |> parse_mtl_directive line)
  (* DEBUG *)
  |> List.of_seq
  |> List.length |> Printf.printf "%d\n"
