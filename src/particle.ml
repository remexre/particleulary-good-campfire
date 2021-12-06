open Assets
open Tgl3

module Particle = struct

  type pair = {mutable x:float; mutable y:float}

  type particle = {
    mutable pos:pair;
    mutable vel:pair;
    mutable acc:pair;
    mutable age:float;
    mutable texture:Texture.t;
  }

  let apply_force_to_particle (p : particle) ((f1, f2) : float * float) =
    p.acc.x <- p.acc.x +. f1;
    p.acc.y <- p.acc.y +. f2

  let update (p : particle) =
    (*update velocity*)
    p.vel.x <- p.vel.x +. p.acc.x;
    p.vel.y <- p.vel.y +. p.acc.y;
    (*update position*)
    p.pos.x <- p.pos.x +. p.vel.x;
    p.pos.y <- p.pos.y +. p.vel.y;
    (*update age*)
    p.age <- p.age +. 2.0;
    (*reset acceleration*)
    p.acc.x <- 0.0;
    p.acc.y <- 0.0

  (*TO DO: render an individual particle*)

  let alive (p : particle) =
    if (p.age >= 75.0) then false else true 

end