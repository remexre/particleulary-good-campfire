type scene

val init_scene : Particle_system.particle_system -> Camera.t -> scene

val render : scene -> unit
