type t = {
  mutable pos : Vec3.t;
  mutable vel : Vec3.t;
  mutable acc : Vec3.t;
  mutable age : float;
}

let init (p : Vec3.t) =
  let np =
    {
      pos = p;
      vel =
        ( Random.float 10.0 *. 0.3,
          Random.float 10.0 *. 0.3,
          Random.float 10.0 *. 0.3 );
      acc = Vec3.zero;
      age = 0.0;
    }
  in
  np

let apply_force_to_particle (p : t) (f : Vec3.t) =
  let x, y, z = p.acc in
  let f1, f2, f3 = f in
  p.acc <- (x +. f1, y +. f2, z +. f3)

let update (p : t) =
  (*update position & velocity*)
  let vx, vy, vz = p.vel in
  let ax, ay, az = p.acc in
  let px, py, pz = p.pos in
  p.vel <- (vx +. ax, vy +. ay, vz +. az);
  let vnx, vny, vnz = p.vel in
  p.pos <- (px +. vnx, py +. vny, pz +. vnz);
  (*update age*)
  p.age <- p.age +. 2.0;
  (*reset acceleration*)
  p.acc <- (0.0, 0.0, 0.0)

let animate (p : t) = update p

(*TO DO: render an individual t*)
(*let render (p : t) =*)

let alive (p : t) = if p.age >= 75.0 then false else true
