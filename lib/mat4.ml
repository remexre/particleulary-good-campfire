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

let perspective ~(fovy : float) ~aspect ~near ~far =
  let tan_half_fovy = tan (fovy /. 2.0) in
  ( (1.0 /. (aspect *. tan_half_fovy), 0.0, 0.0, 0.0),
    (0.0, 1.0 /. tan_half_fovy, 0.0, 0.0),
    (0.0, 0.0, -.(far +. near) /. (far -. near), -1.0),
    (0.0, 0.0, -.(2.0 *. far *. near /. (far -. near)), 0.0) )
