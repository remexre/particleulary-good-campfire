open Util

type t = Vec4.t * Vec4.t * Vec4.t * Vec4.t

let identity =
  ( (1.0, 0.0, 0.0, 0.0),
    (0.0, 1.0, 0.0, 0.0),
    (0.0, 0.0, 1.0, 0.0),
    (0.0, 0.0, 0.0, 1.0) )

let to_array (v1, v2, v3, v4) =
  Array.concat (List.map Vec4.to_array [ v1; v2; v3; v4 ])

let to_bigarray =
  Bigarray.Array1.of_array Bigarray.Float32 Bigarray.C_layout % to_array
