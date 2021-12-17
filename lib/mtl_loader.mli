open Assets

module StringMap : Map.S with type key = string

type mat = {
  ambient : float * float * float;
  diffuse : float * float * float;
  diffuse_map : Texture.t option;
  specular : float * float * float;
  specular_exponent : float;
}

val load_file : path:string -> mat StringMap.t
