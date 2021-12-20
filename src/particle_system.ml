type t = {
  center : Vec3.t;
  lighting : Particle.t DynArr.t;
  visible : Particle.t DynArr.t;
}

let init (center : Vec3.t) =
  {
    center;
    lighting =
      DynArr.init ~capacity:128 ~length:128 (fun _ -> Particle.init center);
    visible =
      DynArr.init ~capacity:1000 ~length:1000 (fun _ -> Particle.init center);
  }

let apply_force_to_all_particles (ps : t) (dir : Vec3.t) =
  DynArr.iter (fun p -> Particle.apply_force_to_particle p dir) ps.visible

let add_particle (ps : t) = DynArr.push ps.visible (Particle.init ps.center)

let add_particles (ps : t) (n : int) = Util.dotimes n (fun _ -> add_particle ps)

let restore_lights (ps : t) : unit =
  let n = 128 - DynArr.length ps.lighting in
  Util.dotimes n (fun _ -> DynArr.push ps.lighting (Particle.init ps.center))

let animate (ps : t) (dt : float) =
  DynArr.retain
    (fun (p : Particle.t) ->
      Particle.animate p dt;
      Particle.alive p)
    ps.visible;
  DynArr.retain
    (fun (p : Particle.t) ->
      Particle.animate p dt;
      p.age < 0.4)
    ps.lighting

let get_lighting_particles ps = ps.lighting

let get_visible_particles ps = ps.visible

let sort_visible_by_distance_from { visible; _ } from =
  DynArr.sort_by_key
    (fun (p : Particle.t) -> Vec3.(-.magnitude2 (p.pos - from)))
    visible
