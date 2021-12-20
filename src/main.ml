open Tgl3

let main () : unit =
  Window.with_window (fun window ->
      Printf.printf "OpenGL driver from %s\n"
        (Option.get (Gl.get_string Gl.vendor));
      let camera = Camera.init (0.0, 0.5, 0.8) window in
      let particle_system = Particle_system.init (0.0, 0.0, -1.0) in
      let scene = Render.init_scene particle_system camera in
      Window.loop ~window (fun dt events ->
          Camera.process_events camera events dt;

          (* TODO: Physics update *)
          let dir = (0.0, 0.025, 0.0) in
          Particle_system.apply_force_to_all_particles particle_system dir;
          Particle_system.animate particle_system dt;
          Particle_system.add_particles particle_system 10;

          Render.render scene))

let () = main ()
