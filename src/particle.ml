type particle = {
  mutable pos: (float * float);
  mutable vel: (float * float);
  mutable acc: (float * float);
  mutable age:float;
}

let init (p : (float * float)) =
  let np = { pos = p;
             vel = ((Random.float 10.0) *. 0.3, (Random.float 10.0) *. 0.3);
             acc = (0.0, 0.0);
             age = 0.0}
  in np

let apply_force_to_particle (p : particle) (f : (float * float)) =
  let (x, y) = p.acc in
    let (f1, f2) = f in
      p.acc <- (x +. f1, y +. f2)

let update (p : particle) =
  (*update position & velocity*)
  let (vx, vy) = p.vel in
    let (ax, ay) = p.acc in
      let (px, py) = p.pos in
        p.pos <- (px +. (vx +. ax), py +. (vy +. ay));
        (*update age*)
        p.age <- p.age +. 2.0;
        (*reset acceleration*)
        p.acc <- (0.0, 0.0)

let animate (p : particle) = update p

  (*TO DO: render an individual particle*)
  (*let render (p : particle) =*)

let alive (p : particle) =
  if (p.age >= 75.0) then false else true 
