type t = {
  mutable particles : Particle.t list;
  mutable start : float * float * float;
}

val init : int -> float * float * float -> t

val apply_force_to_all_particles : t -> float * float * float -> unit

val add_particle : t -> unit

val add_particles : t -> int -> unit

val animate : t -> unit
