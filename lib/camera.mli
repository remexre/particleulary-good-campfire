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

val view : t -> Mat4.t

val init : Vec3.t -> (int * int) -> t

val process_input : t -> Window.event -> float -> unit