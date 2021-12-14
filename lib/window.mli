type event = Key of GLFW.key * GLFW.key_action

type t

val with_window : (t -> 'a) -> 'a

val loop : window:t -> (float -> event list -> unit) -> unit