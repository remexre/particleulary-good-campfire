type t = Vec4.t * Vec4.t * Vec4.t * Vec4.t

val identity : t

val to_array : t -> float array

val to_bigarray :
  t -> (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t

val transpose : t -> t

val ( * ) : t -> t -> t

val perspective : fovy:float -> aspect:float -> near:float -> far:float -> t

val scale : x:float -> y:float -> z:float -> t

val scale_uniform : float -> t

val translate : x:float -> y:float -> z:float -> t
