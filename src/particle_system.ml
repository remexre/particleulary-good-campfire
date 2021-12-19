type t = { mutable particles : Particle.t list; mutable start : Vec3.t }

let init (num_particles : int) (s : Vec3.t) =
  let rec init_particles (iter : int) lst =
    if iter = 0 then lst else init_particles (iter - 1) (Particle.init s :: lst)
  in
  let ps = { particles = init_particles num_particles []; start = s } in
  ps

let apply_force_to_all_particles (ps : t) (dir : Vec3.t) =
  let rec apply_force plst =
    match plst with
    | [] -> ()
    | p :: pars ->
        Particle.apply_force_to_particle p dir;
        apply_force pars
  in
  apply_force ps.particles
(*List.map (fun p -> Particle.apply_force_to_particle p dir) ps.particles*)

let add_particle (ps : t) =
  let p : Particle.t = Particle.init ps.start in
  let newlst = p :: ps.particles in
  ps.particles <- newlst

let rec add_particles (ps : t) (n : int) =
  match n with
  | 0 -> ()
  | _ ->
      add_particle ps;
      add_particles ps (n - 1)

let animate (ps : t) =
  let rec go (cl : Particle.t list) (nl : Particle.t list) =
    match cl with
    | [] -> nl
    | p :: ps ->
        Particle.animate p;
        if not (Particle.alive p) then go ps nl else go ps (p :: nl)
  in
  ps.particles <- go ps.particles []
