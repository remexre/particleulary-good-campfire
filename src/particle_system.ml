open Particle
open Tgl3

type particle_system = {
  mutable particles: Particle.particle list;
  mutable start: Particle.pair;
  mutable texture:Texture.t;
}

let init (num_particles : int) (s : Particle.pair) (t : Texture.t) =
  let rec init_particles (iter : int) lst = 
    if (iter = 0) then lst 
    else init_particles (iter-1) ((Particle.init s t) :: lst)
  in
    (let ps = { particles = init_particles num_particles [];
                start = {x = s.x; y = s.y};
                texture = t}
    in ps)

let apply_force_to_all_particles (ps: particle_system) (dir: Particle.pair) =
    List.map (fun p -> Particle.apply_force_to_particle p dir) ps.particles

let add_particle (ps: particle_system) =
  let p : Particle.particle = Particle.init ps.start ps.texture in
  p :: ps.particles

let animate (ps : particle_system) = ps.particles <- go ps.particles []

let rec go (cl : Particle.particle list) (nl : Particle.particle list) =
  match cl with
    | [] -> nl
    | p::ps -> (animate p; 
                if ((alive(p)) = false) then go ps nl
                else go ps p::nl)