type t = {
  mutable pos : Vec3.t;
  mutable vel : Vec3.t;
  mutable acc : Vec3.t;
  mutable age : float;
}

val init : Vec3.t -> t

val apply_force_to_particle : t -> Vec3.t -> unit

val update : t -> float -> unit

val animate : t -> float -> unit

val alive : t -> bool
