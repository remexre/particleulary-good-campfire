open Util

type t = Vec4.t * Vec4.t * Vec4.t * Vec4.t

let scale ~(x : float) ~(y : float) ~(z : float) : t =
  ( (x, 0.0, 0.0, 0.0),
    (0.0, y, 0.0, 0.0),
    (0.0, 0.0, z, 0.0),
    (0.0, 0.0, 0.0, 1.0) )

let scale_uniform amount = scale ~x:amount ~y:amount ~z:amount

let identity = scale_uniform 1.0

let to_array (v1, v2, v3, v4) =
  Array.concat (List.map Vec4.to_array [ v1; v2; v3; v4 ])

let to_bigarray =
  Bigarray.Array1.of_array Bigarray.Float32 Bigarray.C_layout % to_array

let transpose
    ( (x11, x12, x13, x14),
      (x21, x22, x23, x24),
      (x31, x32, x33, x34),
      (x41, x42, x43, x44) ) =
  ( (x11, x21, x31, x41),
    (x12, x22, x32, x42),
    (x13, x23, x33, x43),
    (x14, x24, x34, x44) )

let ( * ) (l1, l2, l3, l4) r =
  let r1, r2, r3, r4 = transpose r in
  Vec4.
    ( (dot l1 r1, dot l1 r2, dot l1 r3, dot l1 r4),
      (dot l2 r1, dot l2 r2, dot l2 r3, dot l2 r4),
      (dot l3 r1, dot l3 r2, dot l3 r3, dot l3 r4),
      (dot l4 r1, dot l4 r2, dot l4 r3, dot l4 r4) )

let perspective ~fovy ~aspect ~near ~far =
  let tan_half_fovy = tan (fovy /. 2.0) in
  ( (1.0 /. (aspect *. tan_half_fovy), 0.0, 0.0, 0.0),
    (0.0, 1.0 /. tan_half_fovy, 0.0, 0.0),
    (0.0, 0.0, -.(far +. near) /. (far -. near), -1.0),
    (0.0, 0.0, -.(2.0 *. far *. near /. (far -. near)), 0.0) )

let translate ~(x : float) ~(y : float) ~(z : float) : t =
  ( (1.0, 0.0, 0.0, 0.0),
    (0.0, 1.0, 0.0, 0.0),
    (0.0, 0.0, 1.0, 0.0),
    (x, y, z, 1.0) )
