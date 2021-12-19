open Assets
open Util

type illumination_model = Highlight | TransparencyAndRayTracedReflections

type mtl_directive =
  | NewMTL of string
  | Illum of illumination_model
  | AmbientColor of float * float * float
  | DiffuseColor of float * float * float
  | SpecularColor of float * float * float
  | SpecularExponent of float
  | Dissolve of float
  | TransmissionFilter of float * float * float
  | IndexOfRefraction of float
  | MapDiffuseColor of string
  | EmissiveColor of float * float * float

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

type mat = {
  ambient : float * float * float;
  diffuse : float * float * float;
  diffuse_map : Texture.t option;
  specular : float * float * float;
  specular_exponent : float;
}

let default_mat =
  {
    ambient = (0.0, 0.0, 0.0);
    diffuse = (0.0, 0.0, 0.0);
    diffuse_map = None;
    specular = (0.0, 0.0, 0.0);
    specular_exponent = 0.0;
  }

let finish_state = function
  | Some (name, mat), materials -> StringMap.add name mat materials
  | None, materials -> materials

let update_state mtl_path (current_material, materials) = function
  | NewMTL name ->
      (Some (name, default_mat), finish_state (current_material, materials))
  | Illum _ ->
      Printf.eprintf "Warning: skipping Illum\n";
      (current_material, materials)
  | AmbientColor (r, g, b) ->
      let name, mat = Option.get current_material in
      (Some (name, { mat with ambient = (r, g, b) }), materials)
  | DiffuseColor (r, g, b) ->
      let name, mat = Option.get current_material in
      (Some (name, { mat with diffuse = (r, g, b) }), materials)
  | SpecularColor (r, g, b) ->
      let name, mat = Option.get current_material in
      (Some (name, { mat with specular = (r, g, b) }), materials)
  | SpecularExponent k ->
      let name, mat = Option.get current_material in
      (Some (name, { mat with specular_exponent = k }), materials)
  | Dissolve _ ->
      Printf.eprintf "Warning: skipping Dissolve\n";
      (current_material, materials)
  | TransmissionFilter _ ->
      Printf.eprintf "Warning: skipping TransmissionFilter\n";
      (current_material, materials)
  | IndexOfRefraction _ ->
      Printf.eprintf "Warning: skipping IndexOfRefraction\n";
      (current_material, materials)
  | MapDiffuseColor name ->
      let path = join_paths (Filename.dirname mtl_path) name in
      let texture =
        try Texture.load path
        with exc ->
          failf "Failed to load texture %s: %s" path (Printexc.to_string exc)
      in

      let name, mat = Option.get current_material in
      (Some (name, { mat with diffuse_map = Some texture }), materials)
  | EmissiveColor _ ->
      Printf.eprintf "Warning: skipping EmissiveColor\n";
      (current_material, materials)

let load_file ~(path : string) =
  read_file_to_string ~path |> String.split_on_char '\n' |> List.to_seq
  |> Seq.map (List.hd % String.split_on_char '#')
  |> Seq.map String.trim
  |> Seq.filter (( <> ) "")
  |> Seq.map (fun line ->
         String.split_on_char ' ' line
         |> List.filter (( <> ) "")
         |> parse_mtl_directive line)
  |> Seq.fold_left (update_state path) (None, StringMap.empty)
  |> finish_state
