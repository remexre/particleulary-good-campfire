(* Invariants:
 * - len <= Array.length storage
 * - forall i >= len, storage.(i) = None
 *)
type 'a t = { mutable storage : 'a option array; mutable len : int }

let init ~capacity ~length f =
  {
    storage =
      Array.init capacity (fun i -> if i < length then Some (f i) else None);
    len = length;
  }

let make ~capacity = init ~capacity ~length:0 (fun _ -> failwith "impossible")

let capacity { storage; _ } = Array.length storage

let length { len; _ } = len

let get { storage; len } i =
  match Array.get storage i with
  | Some x -> x
  | None ->
      Printf.ksprintf invalid_arg
        "Index %d out of bounds for a DynArr.t of length %d" i len

let set { storage; len } i x =
  if len >= i then
    Printf.ksprintf invalid_arg
      "Index %d out of bounds for a DynArr.t of length %d" i len;
  storage.(i) <- Some x

let grow dynarr =
  if dynarr.len = 0 then dynarr.storage <- Array.make 10 None
  else
    dynarr.storage <-
      Array.init (dynarr.len * 2) (fun i ->
          if i < dynarr.len then dynarr.storage.(i) else None)

let push dynarr x =
  if Array.length dynarr.storage = dynarr.len then grow dynarr;
  dynarr.storage.(dynarr.len) <- Some x;
  dynarr.len <- dynarr.len + 1

let rec iteri_range dynarr f ~lo ~hi =
  if lo < hi then (
    f lo (get dynarr lo);
    iteri_range dynarr f ~lo:(lo + 1) ~hi)

let iteri f dynarr = iteri_range dynarr f ~lo:0 ~hi:(length dynarr)

let iter f = iteri (fun _ -> f)

let retain pred dynarr =
  (* We keep two different indices in the main loop, the index of the next
   * place we'll put an element into, and the index of the next element to
   * test. Initially these are both zero, but when an element is removed by the
   * predicate, the next_index is incremented but the put_index is not. When
   * the next_index reaches the length of the dynamic array, all values between
   * the put_index and the length are deleted, and the length is set to the
   * put_index.
   *)

  (* Primitive recursive on (dynarr.len - next_index).
   * Invariants:
   * - put_index <= next_index
   * - next_index <= dynarr.len
   *)
  let rec test_loop put_index next_index =
    if next_index = dynarr.len then
      (* We got to the end of the array, so this loop is done and clear_loop
       * needs put_index.
       *)
      put_index
    else if pred (Option.get dynarr.storage.(next_index)) then (
      (* The test passed, so we keep this element and keep going. *)
      dynarr.storage.(put_index) <- dynarr.storage.(next_index);
      test_loop (put_index + 1) (next_index + 1))
    else
      (* The test failed, so we check a new element while ignoring this one. *)
      test_loop put_index (next_index + 1)
  in

  let new_length = test_loop 0 0 in
  (* Clear the rest of the array. (This breaks the second invariant of t.) *)
  Util.dotimes (dynarr.len - new_length) (fun i ->
      dynarr.storage.(new_length + i) <- None);
  (* Set the length, restoring the second invariant of t. *)
  dynarr.len <- new_length

let sort_by_key sort_key dynarr =
  Array.fast_sort
    (fun l r ->
      match (l, r) with
      | None, None -> 0
      | Some _, None -> -1
      | None, Some _ -> 1
      | Some l, Some r -> compare (sort_key l) (sort_key r))
    dynarr.storage
