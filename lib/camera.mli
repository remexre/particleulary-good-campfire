type t = {
  mutable camera_pos : Vec3.t;
  camera_speed : float;
  camera_direction : Vec3.t;
  camera_right : Vec3.t;
  camera_up : Vec3.t;
  camera_front : Vec3.t;
}

val view : t -> Mat4.t

val init : Vec3.t -> t

val process_input : t -> Window.event -> unit