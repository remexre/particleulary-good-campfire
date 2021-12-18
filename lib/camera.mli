type t = {
  (* camera *)
  mutable camera_pos : Vec3.t;
  mutable camera_front : Vec3.t;
  mutable camera_up : Vec3.t;

  (* angles *)
  mutable yaw : float;
  mutable pitch : float;

  (* options *)
  mutable last_mouse_pos : (float * float);
  mutable movement_speed : float;

}

val view : t -> Mat4.t

val init : Vec3.t -> Window.t -> t

val process_input : t -> Window.event -> float -> unit