open Tgl3

let render () =
  Gl.clear_color 0.0 0.0 0.0 1.0;
  Gl.clear_depth 0.0;
  Gl.clear (Int.logor Gl.color_buffer_bit Gl.depth_buffer_bit)
