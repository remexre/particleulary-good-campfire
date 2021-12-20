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

val view : t -> Mat4.t

val init : Vec3.t -> Window.t -> t

val process_events : t -> Window.event list -> float -> unit
