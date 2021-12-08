open Tgl3

let main () : unit =
  Window.with_window (fun window ->
      Printf.printf "OpenGL driver from %s\n"
        (Option.get (Gl.get_string Gl.vendor));

      let particle_system = Particle_system.init 5 (1.0, 1.0) in
      let scene = Render.init_scene particle_system in
      Window.loop ~window (fun dt events ->
          (* TODO: Actually handle input events! For now, we just print how many there were. *)
          let l = List.length events in
          if l > 0 then Printf.printf "%d events\n%!" l;

          (* TODO: Physics update *)
          let _ = dt in

          Render.render scene))

let () = main ()
