type particle = {
  mutable pos: (float * float * float);
  mutable vel: (float * float * float);
  mutable acc: (float * float * float);
  mutable age:float;
}

let init (p : (float * float * float)) =
  let np = { pos = p;
             vel = ((Random.float 10.0) *. 0.3, (Random.float 10.0) *. 0.3, (Random.float 10.0) *. 0.3);
             acc = (0.0, 0.0, 0.0);
             age = 0.0}
  in np

let apply_force_to_particle (p : particle) (f : (float * float * float)) =
  let (x, y, z) = p.acc in
    let (f1, f2, f3) = f in
      p.acc <- (x +. f1, y +. f2, z +. f3)

let update (p : particle) =
  (*update position & velocity*)
  let (vx, vy, vz) = p.vel in
    let (ax, ay, az) = p.acc in
      let (px, py, pz) = p.pos in
        p.vel <- (vx +. ax, vy +. ay, vz +.az);
        let (vnx, vny, vnz) = p.vel in
          p.pos <- (px +. vnx, py +. vny, pz +. vnz);
          (*update age*)
          p.age <- p.age +. 2.0;
          (*reset acceleration*)
          p.acc <- (0.0, 0.0, 0.0)

let animate (p : particle) = update p

  (*TO DO: render an individual particle*)
  (*let render (p : particle) =*)

let alive (p : particle) =
  if (p.age >= 75.0) then false else true 
