let assets_dir = "../../../assets"

let objs =
  List.map
    (Util.join_paths assets_dir)
    [
      (* "Pine4m/_.obj/Pine_4m.obj"; *)
      "campfire/OBJ/Campfire.obj";
      "campfire/OBJ/Campfire_clean.OBJ";
      "mushrooms.obj";
      "sphere.obj";
      "trees.obj";
    ]

let mtls =
  List.map
    (Util.join_paths assets_dir)
    [
      "Pine4m/_.obj/Pine_4m.mtl";
      "campfire/OBJ/Campfire.mtl";
      (* "campfire/OBJ/Campfire_clean.mtl"; *)
      "mushrooms.mtl";
      "trees.mtl";
    ]

let () =
  List.iter
    (fun path ->
      try ignore (Obj_loader.load_file ~path)
      with exc ->
        Util.failf "failed to load OBJ %S: %s" path (Printexc.to_string exc))
    objs;
  List.iter
    (fun path ->
      try ignore (Mtl_loader.load_file ~path)
      with exc ->
        Util.failf "failed to load MTL %S: %s" path (Printexc.to_string exc))
    mtls
