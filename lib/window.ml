type event = CursorPos of float * float | Key of GLFW.key * GLFW.key_action

type t = GLFW.window * event Queue.t

let with_glfw (body : unit -> 'a) : 'a =
  Util.bracket
    (fun () ->
      GLFW.init ();
      Printf.printf "Inited GLFW version %s\n" (GLFW.getVersionString ()))
    GLFW.terminate body

let make_window () : t =
  (* Request OpenGL 3.3. *)
  GLFW.windowHint ~hint:GLFW.ClientApi ~value:GLFW.OpenGLApi;
  GLFW.windowHint ~hint:GLFW.ContextVersionMajor ~value:3;
  GLFW.windowHint ~hint:GLFW.ContextVersionMinor ~value:3;
  GLFW.windowHint ~hint:GLFW.OpenGLForwardCompat ~value:true;
  GLFW.windowHint ~hint:GLFW.OpenGLProfile ~value:GLFW.CoreProfile;

  (* Set up borderless fullscreen on the primary monitor. *)
  let monitor = GLFW.getPrimaryMonitor () in
  let video_mode = GLFW.getVideoMode ~monitor in
  GLFW.windowHint ~hint:GLFW.RedBits ~value:(Some video_mode.red_bits);
  GLFW.windowHint ~hint:GLFW.GreenBits ~value:(Some video_mode.green_bits);
  GLFW.windowHint ~hint:GLFW.BlueBits ~value:(Some video_mode.blue_bits);
  GLFW.windowHint ~hint:GLFW.RefreshRate ~value:(Some video_mode.refresh_rate);

  (* Create the window. *)
  let window =
    GLFW.createWindow ~width:video_mode.width ~height:video_mode.height
      ~title:"particleulary-good-campfire" ~monitor ()
  in

  (* Configure OpenGL to use the window. *)
  GLFW.makeContextCurrent ~window:(Some window);

  (* Turn on VSync. *)
  GLFW.swapInterval ~interval:1;

  (* Create the event queue and register callbacks to push events to it. *)
  let events = Queue.create () in
  ignore
    (GLFW.setCursorPosCallback ~window
       ~f:(Some (fun _ x y -> Queue.push (CursorPos (x, y)) events)));
  ignore
    (GLFW.setKeyCallback ~window
       ~f:(Some (fun _ key _ action _ -> Queue.push (Key (key, action)) events)));

  (* Return the window and queue. *)
  (window, events)

let cleanup_window ((window, _queue) : t) : unit =
  GLFW.makeContextCurrent ~window:None;
  GLFW.destroyWindow ~window

let with_window (body : t -> 'a) : 'a =
  with_glfw (fun () -> Util.bracket make_window cleanup_window body)

let loop ~(window : t) (body : float -> event list -> unit) : unit =
  let window, queue = window in
  let rec inner_loop (last_time : float) : unit =
    if GLFW.windowShouldClose ~window then ()
    else
      let start_time = GLFW.getTime () in
      let dt = start_time -. last_time in
      body dt (Util.list_of_queue queue);
      GLFW.swapBuffers ~window;
      GLFW.pollEvents ();
      inner_loop start_time
  in
  inner_loop (GLFW.getTime ())
