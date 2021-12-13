type t = Vec4.t * Vec4.t * Vec4.t * Vec4.t

val identity : t

val to_array : t -> float array

val to_bigarray :
  t -> (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t

val perspective :
  float -> float -> float -> float -> t ref
