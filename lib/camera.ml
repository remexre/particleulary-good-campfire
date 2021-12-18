(* Based on: https://learnopengl.com/Getting-started/Camera*)
type m = {
  mutable first_mouse : bool;
  mutable last_pos : (float * float);
}

type t = {
  (* camera *)
  mutable camera_pos : Vec3.t;
  mutable camera_front : Vec3.t;
  mutable camera_up : Vec3.t;

  (* angles *)
  mutable yaw : float;
  mutable pitch : float;

  (* options *)
  mouse : m;
  mutable movement_speed : float;

}

let view (c : t) = 
  let (x, y, z) = c.camera_pos in
  let t = Mat4.translate ~x ~y ~z in
  let to_radians deg = deg *. (180.0 /. Float.pi) in
  let (pitch, yaw, roll) = (0.0 -. to_radians(c.pitch), 0.0 -. to_radians(c.yaw), 0.0) in
  let r = Mat4.rotate_euler ~pitch ~yaw ~roll in
  Mat4.(t * r)

let camera_direction pos =
  let camera_target = Vec3.zero in
    Vec3.normalize Vec3.(pos - camera_target)

let camera_right dir =
  let up = (0.0, 1.0, 0.0) in
    Vec3.cross up dir

let init (pos : Vec3.t) ((w, h) : (int * int)) =
  let dir = camera_direction pos in
  let right = camera_right dir in
  let up = Vec3.cross dir right in
  let front = (0.0, 0.0, 0.0-.1.0) in
    {
      camera_pos = pos;
      camera_front = front;
      camera_up = up;

      yaw = 0.0 -. 90.0;
      pitch = 0.0;

      mouse = {first_mouse = true; last_pos = (Float.of_int (w/2), Float.of_int (h/2));};
      movement_speed = 0.5;
    }

let process_cursor (c : t) (xoffset, yoffset) =
  let s = 0.0001 in
  let (x, y) = (s *. xoffset, s *. yoffset) in
    c.yaw <- c.yaw +. x;
    c.pitch <- c.pitch +. y;
    if (c.pitch > 89.0) then c.pitch <- 89.0;
    if (c.pitch < (0.0 -. 89.0)) then c.pitch <- (0.0 -. 89.0)

let process_input (c : t) (input : Window.event) (dt : float) =
  match input with
  | CursorPos (x, y) -> (
    if (c.mouse.first_mouse = true) 
      then (c.mouse.last_pos <- (x, y); c.mouse.first_mouse <- false);
    let (lx, ly) = c.mouse.last_pos in
      process_cursor c (x -. lx, ly -. y);
      c.mouse.last_pos <- (x, y)
  )
  | Key (key, action) -> (
      let c_cfcu = Vec3.normalize (Vec3.cross c.camera_front c.camera_up) in
      let speed = c.movement_speed *. dt in
      match key with
      | GLFW.W -> c.camera_pos <- Vec3.(c.camera_pos + (c.camera_front * speed))
      | GLFW.S -> c.camera_pos <- Vec3.(c.camera_pos - (c.camera_front * speed))
      | GLFW.A -> c.camera_pos <- Vec3.(c.camera_pos - (c_cfcu * speed))
      | GLFW.D -> c.camera_pos <- Vec3.(c.camera_pos + (c_cfcu * speed))
      | GLFW.LeftShift -> ( match action with
                              GLFW.Press -> c.movement_speed <- c.movement_speed *. 2.0
                              | GLFW.Release -> c.movement_speed <- c.movement_speed *. 0.5
                              | _ -> ())
      | _ -> ())