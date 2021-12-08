open Particle

type particle_system = {
  mutable particles: Particle.particle list;
  mutable start: (float * float);
}

let init (num_particles : int) (s : (float * float)) =
  let rec init_particles (iter : int) lst = 
    if (iter = 0) then lst 
    else init_particles (iter-1) ((Particle.init s) :: lst)
  in
    (let ps = { particles = init_particles num_particles [];
                start = s}
    in ps)

let apply_force_to_all_particles (ps: particle_system) (dir: (float * float)) =
    List.map (fun p -> Particle.apply_force_to_particle p dir) ps.particles

let add_particle (ps: particle_system) =
  let p : Particle.particle = Particle.init ps.start in
  p :: ps.particles

let animate (ps : particle_system) = 
  let rec go (cl : Particle.particle list) (nl : Particle.particle list) =
    match cl with
      | [] -> nl
      | p::ps -> (Particle.animate p; 
                  if ((alive(p)) = false) then go ps nl
                  else go ps (p::nl))
  in
  ps.particles <- go ps.particles []