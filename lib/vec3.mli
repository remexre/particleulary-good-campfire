type t = float * float * float

val zero : t

val ( + ) : t -> t -> t

val ( - ) : t -> t -> t

val ( * ) : t -> float -> t

val cross : t -> t -> t

val dot : t -> t -> float

val magnitude : t -> float

val magnitude2 : t -> float

val normalize : t -> t
