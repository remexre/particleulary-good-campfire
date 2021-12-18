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
  (*mouse_callback : mc;*)
}

val view : t -> Mat4.t

val init : Vec3.t -> t

val process_input : t -> Window.event -> float -> unit