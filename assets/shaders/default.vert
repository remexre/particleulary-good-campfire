#version 330

/*
 * In the absence of a stronger type system (e.g. [0]), we use Hungarian
 * Notation for vectors, so it's easier to find bugs involving confusing which
 * coordinate space a vector is intended to be in. See [1] for more information
 * on the different spaces.
 *
 * - ms: Model Space, the space used in the model itself. ([1] calls this Local
 *   Space.)
 * - ws: World Space, the space used for physics and other interactions between
 *   objects.
 * - vs: View Space, the space as viewed by the camera. The camera is at the
 *   origin, and points towards (0, 0, -1). (NR: I'm likely to get this
 *   backwards and sometimes assume the camera points towards (0, 0, 1)...).
 * - cs: Clip Space, the space used by the hardware to perform clipping (hence
 *   the name).
 *
 * The model, view, and projection matrices are transformations between these
 * spaces: model converts ms to ws, view converts ws to vs, and proj converts
 * vs to cs.
 *
 * [0]: https://doi.org/10.1145/3428241
 * [1]: https://learnopengl.com/Getting-started/Coordinate-Systems
 */

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

in vec3 msPosition;
in vec3 msNormals;
in vec2 texCoords;

// We need to manually specify anything we want to pass to the fragment shader,
// even if it's a vertex attribute.
out vec2 texCoordsFrag;
out vec4 wsNormals;

void main() {
  gl_Position = proj * view * model * vec4(msPosition, 1);
  wsNormals = model * vec4(msNormals, 0);
  texCoordsFrag = texCoords;
}
