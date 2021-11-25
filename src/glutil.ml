open Tgl3

let get_set_int_array =
  Bigarray.Array1.create Bigarray.Int32 Bigarray.C_layout 1

(* A helper for calling functions that return a single integer by writing it to
 * an array, e.g. Gl.get_shaderiv. *)
let get_int : (Gl.uint32_bigarray -> unit) -> int =
 fun f ->
  f get_set_int_array;
  Int32.to_int get_set_int_array.{0}

(* A helper for calling functions that accept a single integer by reading it
 * from an array, e.g. Gl.delete_textures. (This is perhaps not the best name,
 * but it has symmetry with get_int.) *)
let set_int : (Gl.uint32_bigarray -> 'a) -> int -> 'a =
 fun f n ->
  Bigarray.Array1.set get_set_int_array 0 (Int32.of_int n);
  f get_set_int_array
