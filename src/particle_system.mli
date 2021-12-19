type t

val init : int -> Vec3.t -> t

val apply_force_to_all_particles : t -> Vec3.t -> unit

val add_particle : t -> unit

val add_particles : t -> int -> unit

val animate : t -> unit

val iter : (Particle.t -> unit) -> t -> unit

val length : t -> int

val nth : t -> int -> Particle.t
