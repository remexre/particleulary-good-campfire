type mc = {
  mutable first_mouse : bool;
  mutable last_pos : (float * float);
  sensitivity : float;
  mutable yaw : float;
  mutable pitch : float;
}

type t = {
  mutable camera_pos : Vec3.t;
  mutable camera_speed : float;
  camera_direction : Vec3.t;
  camera_right : Vec3.t;
  camera_up : Vec3.t;
  mutable camera_front : Vec3.t;
  mouse_callback : mc;
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
    camera_speed = 0.5;
    camera_direction = cd;
    camera_right = cr;
    camera_up = cu;
    camera_front = cf;
    mouse_callback = 
      {first_mouse = true;
      last_pos = (0.0, 0.0);
      sensitivity = 0.0001;
      yaw = 0.0;
      pitch = 0.0;
      }
    }

let process_cursor (c : t) (xpos, ypos) =
  let mc = c.mouse_callback in
  let (last_x, last_y) =
    if mc.first_mouse
      then (c.mouse_callback.first_mouse <- false; (xpos, ypos))
    else mc.last_pos in
  let s = mc.sensitivity in
  let (offset_x, offset_y) = (s *. (xpos -. last_x), s *. (last_y -. ypos)) in
    c.mouse_callback.last_pos <- (xpos, ypos);
    c.mouse_callback.yaw <- mc.yaw +. offset_x;
    c.mouse_callback.pitch <- mc.pitch +. offset_y;
    if (c.mouse_callback.pitch > 89.0) 
      then c.mouse_callback.pitch <- 89.0;
    if (c.mouse_callback.pitch < (0.0 -. 89.0)) 
      then c.mouse_callback.pitch <- (0.0 -. 89.0);
    let to_radians deg = deg *. (180.0 /. Float.pi) in
    let yaw = c.mouse_callback.yaw in
    let pitch = c.mouse_callback.pitch in
    let direction = ((Float.cos (to_radians (yaw))) *. (Float.cos (to_radians(pitch))),
                     Float.sin (to_radians(pitch)),
                     (Float.sin (to_radians(yaw)) *. Float.cos (to_radians(pitch)))) in
      c.camera_front <- Vec3.normalize(direction)

let process_input (c : t) (input : Window.event) (dt : float) =
  match input with
  | CursorPos (_x, _y) -> (process_cursor c (_x, _y))
  | Key (key, action) -> (
      let c_cfcu = Vec3.normalize (Vec3.cross c.camera_front c.camera_up) in
      let speed = c.camera_speed *. dt in
      match key with
      | GLFW.W -> c.camera_pos <- Vec3.(c.camera_pos + (c.camera_front * speed))
      | GLFW.A -> c.camera_pos <- Vec3.(c.camera_pos - (c.camera_front * speed))
      | GLFW.S -> c.camera_pos <- Vec3.(c.camera_pos - (c_cfcu * speed))
      | GLFW.D -> c.camera_pos <- Vec3.(c.camera_pos + (c_cfcu * speed))
      | GLFW.LeftShift -> ( match action with
                              GLFW.Press -> c.camera_speed <- c.camera_speed *. 2.0
                              | GLFW.Release -> c.camera_speed <- c.camera_speed *. 0.5
                              | _ -> ())
      | _ -> ())
