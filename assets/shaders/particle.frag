#version 330

in vec2 texCoordsFrag;
in float particleAgeFrag;
in vec4 wsNormals;

out vec4 color;

vec4 colorParticle () {

  vec3 goldenPoppy = vec3((250.0/255.0), (192.0/255.0), 0.0);
  vec3 barnRed = vec3(128.0/255.0, 17.0/255.0, 0.0);

  float smokeAge = 30.0;

  if (particleAgeFrag < smokeAge) {
    vec3 c = ((barnRed - goldenPoppy) * (particleAgeFrag/smokeAge)) + goldenPoppy;
    return vec4(c, 1.0);
  }
  
  vec3 c = vec3(132.0/255.0, 136.0/255.0, 132.0/255.0);
  return vec4(c, 0.5);

}

void main() { color = colorParticle(); }
