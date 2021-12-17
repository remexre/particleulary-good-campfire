(* Maybe this should be a function? *)
(* i.e. camera_pos x = x *)

let camera_pos = (0.0, 0.0, 0.3)

let camera_direction = 
  let camera_target = Vec3.zero in
    Vec3.normalize Vec3.(camera_pos - camera_target)

let camera_right =
  let up = (0.0, 1.0, 0.0) in
    Vec3.cross up camera_direction

let camera_up = Vec3.cross camera_direction camera_right

let camera_front = (0.0, 0.0, 0.0-.1.0)

let view = 
  let dir = Vec3.(camera_pos + camera_front) in
    let eye = camera_pos in
      let up = camera_up in
        Mat4.look_at ~eye ~dir ~up
