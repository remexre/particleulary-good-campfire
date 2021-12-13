let assets_dir = "../../../assets"

let objs =
  List.map
    (Util.join_paths assets_dir)
    [
      "Pine4m/_.obj/Pine_4m.obj";
      "campfire/OBJ/Campfire.obj";
      "campfire/OBJ/Campfire_clean.OBJ";
      "mushrooms.obj";
      "sphere.obj";
      "trees.obj";
    ]

let () =
  List.iter
    (fun path ->
      try Obj_loader.load_file path
      with exc ->
        Util.failf "failed to load OBJ %S: %s" path (Printexc.to_string exc))
    objs
