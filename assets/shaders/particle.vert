#version 330

uniform mat4 view;
uniform mat4 proj;

in vec3 msPosition;
in vec3 msNormals;
in vec2 texCoords;
in vec3 wsParticlePos;
in float particleAge;

out vec2 texCoordsFrag;
out float particleAgeFrag;
out vec4 wsNormals;

void main() {
  float size = 0.25 * sin(particleAge / 100.0);
  mat4 scaling = mat4(vec4(size, 0.0, 0.0, 0.0), vec4(0.0, size, 0.0, 0.0),
                      vec4(0.0, 0.0, size, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
  mat4 translation = mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0),
                          vec4(0.0, 0.0, 1.0, 0.0), vec4(wsParticlePos, 1.0));
  mat4 model = translation * scaling;

  gl_Position = proj * view * model * vec4(msPosition, 1);
  wsNormals = normalize(model * vec4(msNormals, 0));
  texCoordsFrag = texCoords;
  particleAgeFrag = particleAge;
}
