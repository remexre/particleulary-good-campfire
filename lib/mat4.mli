type t = Vec4.t * Vec4.t * Vec4.t * Vec4.t

val identity : t

val to_array : t -> float array

val to_bigarray :
  t -> (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t

val transpose : t -> t

val ( * ) : t -> t -> t

val perspective : fovy:float -> aspect:float -> near:float -> far:float -> t

val rotate_pitch : float -> t

val rotate_yaw : float -> t

val rotate_roll : float -> t

val rotate_euler : pitch:float -> yaw:float -> roll:float -> t

val scale : x:float -> y:float -> z:float -> t

val scale_uniform : float -> t

val translate : x:float -> y:float -> z:float -> t

val look_at : eye:(Vec3.t) -> dir:(Vec3.t) -> up:(Vec3.t) -> t