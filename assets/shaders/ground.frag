#version 330 core

uniform sampler2D diffuseTex;
uniform int hasDiffuseTex;

uniform vec3 materialAmbient;
uniform vec3 materialDiffuse;
uniform vec3 materialSpecular;
uniform float specularExponent;

struct light {
  vec3 position;
  float intensity;
  vec3 color;
};
uniform int lightCount;
layout(std140) uniform light_ubo { light lights[128]; }
lightUBO;

in vec2 texCoordsFrag;
in vec4 wsPosition;
in vec4 wsNormals;

out vec4 color;

const float ambientLight = 0.1;

void main() {
  vec3 ambient = materialAmbient * ambientLight;

  vec3 diffuseColor = (hasDiffuseTex != 0)
                          ? texture(diffuseTex, texCoordsFrag).rgb
                          : materialDiffuse;
  float totalDiffuseIntensity = 0.0;
  // for (int i = 0; i < lightCount; i++) {
  vec3 fragToLight = lightUBO.lights[0].position - wsPosition.xyz;

  float diffuseIntensity =
      /* clamp(dot(normalize(fragToLight), wsNormals.xyz), 0.0, 1.0); */
      1.0;
  totalDiffuseIntensity += diffuseIntensity * 0.01 / length(fragToLight);
  // }
  vec3 diffuse = diffuseColor * totalDiffuseIntensity;

  vec3 specular = materialSpecular;

  color = vec4(ambient + diffuse, 1.0);
}
