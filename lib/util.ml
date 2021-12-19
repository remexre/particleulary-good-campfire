module StringMap = Map.Make (String)

let ( % ) f g x = f (g x)

let bracket (init : unit -> 'a) (cleanup : 'a -> unit) (body : 'a -> 'b) : 'b =
  let value = init () in
  Fun.protect ~finally:(fun () -> cleanup value) (fun () -> body value)

let do_iter (n : int) (f : int -> unit) : unit =
  let rec loop (i : int) =
    if i < n then (
      f i;
      loop (i + 1))
  in
  loop 0

let failf fmt = Printf.ksprintf failwith fmt

let flip f x y = f y x

let id x = x

let rec mapM_option f = function
  | [] -> Some []
  | hd :: tl ->
      Option.bind (f hd) (fun hd' ->
          Option.map (fun tl' -> hd' :: tl') (mapM_option f tl))

let or_else (opt : 'a option) (make_default : unit -> 'a option) : 'a option =
  match opt with Some x -> Some x | None -> make_default ()

let unwrap_or_else (opt : 'a option) (make_default : unit -> 'a) : 'a =
  match opt with Some x -> x | None -> make_default ()

let list_of_queue (queue : 'a Queue.t) : 'a list =
  let out = Queue.fold (fun tl hd -> hd :: tl) [] queue in
  Queue.clear queue;
  out

let split_on pred xs =
  List.fold_left
    (fun (current, previous) ele ->
      if pred ele then
        match current with
        | Some current -> (Some [], current :: previous)
        | None -> (Some [], previous)
      else
        match current with
        | Some current -> (Some (ele :: current), previous)
        | None -> (Some [ ele ], previous))
    (None, []) xs
  |> (function Some xs, xss -> xs :: xss | None, xss -> xss)
  |> List.rev_map List.rev

let split_and_group (f : 'a -> ('b, 'c) Either.t option) (xs : 'a Seq.t) :
    'b list * ('c * 'b list) list =
  Seq.fold_left
    (fun state x ->
      match (state, f x) with
      | _, None -> state
      | `Initial ys, Some (Left y) -> `Initial (y :: ys)
      | `Initial ys, Some (Right z) -> `Running (List.rev ys, [], z, [])
      | `Running (init, zss, z, ys), Some (Left y) ->
          `Running (init, zss, z, y :: ys)
      | `Running (init, zss, z, ys), Some (Right z') ->
          `Running (init, (z, List.rev ys) :: zss, z', []))
    (`Initial []) xs
  |> function
  | `Initial ys -> (List.rev ys, [])
  | `Running (init, zss, z, ys) -> (init, List.rev ((z, ys) :: zss))

let string_starts_with ~(prefix : string) (s : string) : bool =
  let prefix_len = String.length prefix in
  prefix = ""
  || (prefix_len <= String.length s && String.sub s 0 prefix_len = prefix)

(* Like Filename.concat, except it resolves leading `./' and `../' components . *)
let rec join_paths (l : string) (r : string) : string =
  if string_starts_with ~prefix:"/" r then r
  else if string_starts_with ~prefix:"./" r then
    join_paths l (String.sub r 2 (String.length r - 2))
  else if string_starts_with ~prefix:"../" r then
    join_paths (Filename.dirname l) (String.sub r 3 (String.length r - 3))
  else Filename.concat l r

let read_file_to_string ~(path : string) : string =
  let ch = open_in_bin path in
  (* Read in 1MB chunks. *)
  let chunk_size = Int.shift_left 1 20 in
  let rec loop (buf : bytes) (buf_len : int) : string =
    let buf = Bytes.extend buf 0 (chunk_size - (Bytes.length buf - buf_len)) in
    let len = input ch buf buf_len chunk_size in
    if len = 0 then Bytes.to_string (Bytes.sub buf 0 buf_len)
    else loop buf (buf_len + len)
  in
  loop (Bytes.create chunk_size) 0

(* Converts the path to an absolute path. Throws an exception if the path does
 * not exist. *)
let realpath : path:string -> string =
  let root_dev_ino : int * int =
    let root_stats = Unix.lstat "/" in
    (root_stats.st_dev, root_stats.st_ino)
  in

  let rec loop ~(path : string) : string =
    let stats = Unix.lstat path in
    let is_root = (stats.st_dev, stats.st_ino) = root_dev_ino in
    let is_symlink = stats.st_kind = S_LNK in

    let basename = Filename.basename path in
    let dirname = Filename.dirname path in

    if path = "." then Unix.getcwd ()
    else if is_symlink then loop ~path:(join_paths dirname (Unix.readlink path))
    else if is_root then "/"
    else if basename = "." then loop ~path:dirname
    else if basename = ".." then Filename.dirname (loop ~path:dirname)
    else Filename.concat (loop ~path:dirname) basename
  in
  loop
