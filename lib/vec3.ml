open Util

type t = float * float * float

let zero = (0.0, 0.0, 0.0)

let ( + ) (lx, ly, lz) (rx, ry, rz) = (lx +. rx, ly +. ry, lz +. rz)

let ( - ) (lx, ly, lz) (rx, ry, rz) = (lx -. rx, ly -. ry, lz -. rz)

let cross (lx, ly, lz) (rx, ry, rz) =
  ((ly *. rz) +. (lz *. ry), (lz *. rx) +. (lx *. rz), (lx *. ry) +. (ly *. rx))

let dot (lx, ly, lz) (rx, ry, rz) = (lx *. rx) +. (ly *. ry) +. (lz *. rz)

let magnitude2 v = dot v v

let magnitude = sqrt % magnitude2

let normalize (x, y, z) =
  let m = magnitude (x, y, z) in
  if m = 0.0 then zero else (x /. m, y /. m, z /. m)
