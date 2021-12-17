type t = {
  mutable camera_pos : Vec3.t;
  camera_speed : float;
  camera_direction : Vec3.t;
  camera_right : Vec3.t;
  camera_up : Vec3.t;
  camera_front : Vec3.t;
}

let camera_direction pos =
  let camera_target = Vec3.zero in
    Vec3.normalize Vec3.(pos - camera_target)

let camera_right dir =
  let up = (0.0, 1.0, 0.0) in
    Vec3.cross up dir

let view (c : t) = 
  let dir = Vec3.(c.camera_pos + c.camera_front) in
    let eye = c.camera_pos in
      let up = c.camera_up in
        Mat4.look_at ~eye ~dir ~up

let init (pos : Vec3.t) =
  let cd = camera_direction pos in
  let cr = camera_right cd in
  let cu = Vec3.cross cd cr in
  let cf = (0.0, 0.0, 0.0-.1.0) in
    {camera_pos = pos;
    camera_speed = 0.05;
    camera_direction = cd;
    camera_right = cr;
    camera_up = cu;
    camera_front = cf;
    }

(* let camera_pos = (0.0, 0.0, 0.3) *)

let process_input (c : t) (input : Window.event) =
  let Key(key, _) = input in
  let c_cfcu = Vec3.normalize (Vec3.cross c.camera_front c.camera_up) in
    match key with
      GLFW.W -> c.camera_pos <- Vec3.(c.camera_pos + (c.camera_front * c.camera_speed))
    | GLFW.A -> c.camera_pos <- Vec3.(c.camera_pos - (c.camera_front * c.camera_speed))
    | GLFW.S -> c.camera_pos <- Vec3.(c.camera_pos - (c_cfcu * c.camera_speed))
    | GLFW.D -> c.camera_pos <- Vec3.(c.camera_pos + (c_cfcu * c.camera_speed))
    | _ -> ()
