type t = { particles : Particle.t DynArr.t; mutable start : Vec3.t }

let init (num_particles : int) (s : Vec3.t) =
  {
    particles =
      DynArr.init ~capacity:num_particles ~length:num_particles (fun _ ->
          Particle.init s);
    start = s;
  }

let apply_force_to_all_particles (ps : t) (dir : Vec3.t) =
  DynArr.iter (fun p -> Particle.apply_force_to_particle p dir) ps.particles

let add_particle (ps : t) = DynArr.push ps.particles (Particle.init ps.start)

let add_particles (ps : t) (n : int) = Util.dotimes n (fun _ -> add_particle ps)

let animate (ps : t) =
  DynArr.retain
    (fun (p : Particle.t) ->
      Particle.animate p;
      Particle.alive p)
    ps.particles

let iteri f { particles; _ } = DynArr.iteri f particles

let length { particles; _ } = DynArr.length particles

let sort_by_distance_from { particles; _ } from =
  DynArr.sort_by_key
    (fun (p : Particle.t) -> Vec3.(magnitude2 (p.pos - from)))
    particles
