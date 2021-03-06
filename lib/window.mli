type event = CursorPos of float * float | Key of GLFW.key * GLFW.key_action

type t

val with_window : (t -> 'a) -> 'a

val loop : window:t -> (float -> event list -> unit) -> unit

val size : window:t -> int * int

val set_cursor : window:t -> xpos:float -> ypos:float -> unit
