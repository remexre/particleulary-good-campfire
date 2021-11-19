let bracket (init : unit -> 'a) (cleanup : 'a -> unit) (body : 'a -> 'b) : 'b =
  let value = init () in
  Fun.protect ~finally:(fun () -> cleanup value) (fun () -> body value)

let or_else (opt : 'a option) (make_default : unit -> 'a option) : 'a option =
  match opt with Some x -> Some x | None -> make_default ()

let unwrap_or_else (opt : 'a option) (make_default : unit -> 'a) : 'a =
  match opt with Some x -> x | None -> make_default ()

let list_of_queue (queue : 'a Queue.t) : 'a list =
  let out = Queue.fold (fun tl hd -> hd :: tl) [] queue in
  Queue.clear queue;
  out
