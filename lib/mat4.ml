open Util

type t = Vec4.t * Vec4.t * Vec4.t * Vec4.t

let identity =
  ( (1.0, 0.0, 0.0, 0.0),
    (0.0, 1.0, 0.0, 0.0),
    (0.0, 0.0, 1.0, 0.0),
    (0.0, 0.0, 0.0, 1.0) )

let matrix = ref identity

let to_array (v1, v2, v3, v4) =
  Array.concat (List.map Vec4.to_array [ v1; v2; v3; v4 ])

let to_bigarray =
  Bigarray.Array1.of_array Bigarray.Float32 Bigarray.C_layout % to_array

let perspective (fovy: float) aspect near far =
  let tan_half_fovy = tan ( fovy /. 2.0 ) in
    let ((_, a2, a3, a4),
         (b1, _, b3, b4),
         (c1, c2, _, _),
         (d1, d2, _, d4)) = ! matrix
    in
      (matrix := (((1.0 /. (aspect *. tan_half_fovy), a2, a3, a4), 
                (b1, (1.0 /. tan_half_fovy), b3, b4), 
                (c1, c2, (-. (far +. near) /. (far -. near)), (-. 1.0)), 
                (d1, d2, (-. ((2.0 *. far *. near) /. (far -. near))), d4)));
       matrix)
