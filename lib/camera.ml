(* Based on: https://learnopengl.com/Getting-started/Camera *)
type t = {
  (* camera *)
  mutable camera_pos : Vec3.t;
  (* angles *)
  mutable yaw : float;
  mutable pitch : float;
  (* options *)
  w : int;
  h : int;
  mutable last_mouse_pos : float * float;
  mutable movement_speed : float;
  mutable w_pressed : bool;
  mutable a_pressed : bool;
  mutable s_pressed : bool;
  mutable d_pressed : bool;
  mutable lshift_pressed : bool;
}

let view (c : t) =
  let x, y, z = c.camera_pos in
  Mat4.(
    translate ~x:(-.x) ~y:(-.y) ~z:(-.z)
    * rotate_euler ~pitch:c.pitch ~yaw:c.yaw ~roll:0.0)

let init (pos : Vec3.t) (window : Window.t) =
  let w, h = Window.size ~window in
  let xpos = Float.of_int (w / 2) in
  let ypos = Float.of_int (h / 2) in
  Window.set_cursor ~window ~xpos ~ypos;
  {
    camera_pos = pos;
    yaw = 0.0;
    pitch = 0.0;
    w;
    h;
    last_mouse_pos = (xpos, ypos);
    movement_speed = 0.5;
    w_pressed = false;
    a_pressed = false;
    s_pressed = false;
    d_pressed = false;
    lshift_pressed = false;
  }

let process_cursor (c : t) (xoffset, yoffset) (dt : float) =
  let clamp x lo hi = if x < lo then lo else if x > hi then hi else x
  and pi2 = Float.pi /. 2.0
  and x = dt *. xoffset (* /. Float.of_int c.w *)
  and y = dt *. yoffset (* /. Float.of_int c.h *) in

  c.yaw <- c.yaw -. x;
  c.pitch <- clamp (c.pitch -. y) (-.pi2) pi2

let process_events (c : t) (events : Window.event list) (dt : float) =
  List.iter
    (let open Window in
    function
    | CursorPos (x, y) ->
        let lx, ly = c.last_mouse_pos in
        if not (lx = x && ly = y) then process_cursor c (lx -. x, ly -. y) dt;
        c.last_mouse_pos <- (x, y)
    | Key (GLFW.W, GLFW.Press) -> c.w_pressed <- true
    | Key (GLFW.W, GLFW.Release) -> c.w_pressed <- false
    | Key (GLFW.A, GLFW.Press) -> c.a_pressed <- true
    | Key (GLFW.A, GLFW.Release) -> c.a_pressed <- false
    | Key (GLFW.S, GLFW.Press) -> c.s_pressed <- true
    | Key (GLFW.S, GLFW.Release) -> c.s_pressed <- false
    | Key (GLFW.D, GLFW.Press) -> c.d_pressed <- true
    | Key (GLFW.D, GLFW.Release) -> c.d_pressed <- false
    | Key (GLFW.LeftShift, GLFW.Press) -> c.lshift_pressed <- true
    | Key (GLFW.LeftShift, GLFW.Release) -> c.lshift_pressed <- false
    | _ -> ())
    events;

  let old_view = view c
  and xyz (x, y, z, _) = (x, y, z)
  and speed = c.movement_speed *. dt *. if c.lshift_pressed then 5.0 else 1.0 in
  let forwards = xyz (Mat4.vecmul old_view (0.0, 0.0, -1.0, 0.0))
  and right = xyz (Mat4.vecmul old_view (1.0, 0.0, 0.0, 0.0)) in

  if c.w_pressed then c.camera_pos <- Vec3.(c.camera_pos + (forwards * speed));
  if c.a_pressed then c.camera_pos <- Vec3.(c.camera_pos - (right * speed));
  if c.s_pressed then c.camera_pos <- Vec3.(c.camera_pos - (forwards * speed));
  if c.d_pressed then c.camera_pos <- Vec3.(c.camera_pos + (right * speed));

  c.camera_pos <-
    (let x, y, z = c.camera_pos in
     (x, (if y < 0.1 then 0.1 else y), z))
