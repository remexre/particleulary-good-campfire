open Assets
open Tgl3

open Random

module Particle = struct

  type pair = {mutable x:float; mutable y:float}

  type particle = {
    mutable pos:pair;
    mutable vel:pair;
    mutable acc:pair;
    mutable age:float;
    mutable texture:Texture.t;
  }

  let init (p : pair) (t : Texture.t) =
    let np = { pos = {x = p.x; y = p.y};
               vel = {x = (Random.float 10.0) *. 0.3; y = (Random.float 10.0) *. 0.3};
               acc = {x = 0.0; y = 0.0};
               age = 0.0;
               texture = t}
    in np

  let apply_force_to_particle (p : particle) (f : pair) =
    p.acc.x <- p.acc.x +. f.x;
    p.acc.y <- p.acc.y +. f.y

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

  let animate (p : particle) = update p

  (*TO DO: render an individual particle*)

  let alive (p : particle) =
    if (p.age >= 75.0) then false else true 

end