type t

val init : Vec3.t -> t

val apply_force_to_all_particles : t -> Vec3.t -> unit

val add_particle : t -> unit

val add_particles : t -> int -> unit

val animate : t -> float -> unit

val get_lighting_particles : t -> Particle.t DynArr.t

val get_visible_particles : t -> Particle.t DynArr.t

val sort_visible_by_distance_from : t -> Vec3.t -> unit
