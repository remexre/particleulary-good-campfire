type t = float * float * float * float

let to_array (x, y, z, w) = [| x; y; z; w |]

let dot (lx, ly, lz, lw) (rx, ry, rz, rw) =
  (lx *. rx) +. (ly *. ry) +. (lz *. rz) +. (lw *. rw)
