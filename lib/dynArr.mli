type 'a t

val init : capacity:int -> length:int -> (int -> 'a) -> 'a t

val make : capacity:int -> 'a t

val capacity : 'a t -> int

val length : 'a t -> int

val get : 'a t -> int -> 'a

val set : 'a t -> int -> 'a -> unit

val push : 'a t -> 'a -> unit

val iter : ('a -> unit) -> 'a t -> unit

val iteri : (int -> 'a -> unit) -> 'a t -> unit

(* https://doc.rust-lang.org/nightly/std/vec/struct.Vec.html#method.retain *)
val retain : ('a -> bool) -> 'a t -> unit

val sort_by_key : ('a -> 'b) -> 'a t -> unit
