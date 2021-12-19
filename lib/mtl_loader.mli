open Assets
open Util

type mat = {
  ambient : float * float * float;
  diffuse : float * float * float;
  diffuse_map : Texture.t option;
  specular : float * float * float;
  specular_exponent : float;
}

val default_mat : mat

val load_file : path:string -> mat StringMap.t
