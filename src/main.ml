open Tgl4

let () =
  (* Initialize GLFW. *)
  GLFW.init ();
  at_exit GLFW.terminate;

  let window = GLFW.createWindow 640 480 "Hello World" () in
  GLFW.makeContextCurrent ~window:(Some window);

  print_endline "Hello, World!";
  print_endline (Option.get (Gl.get_string Gl.vendor))
