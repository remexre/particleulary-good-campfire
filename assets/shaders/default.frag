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
  vec3 diffuseColor = (hasDiffuseTex != 0)
                          ? texture(diffuseTex, texCoordsFrag).rgb
                          : materialDiffuse;
  vec3 ambient = diffuseColor * ambientLight;

  float totalDiffuseIntensity = 0.0;
  for (int i = 0; i < lightCount; i++) {
    light light = lightUBO.lights[i];
    float lightDist = distance(light.position, wsPosition.xyz);
    if (lightDist > 0.0001) {
      vec3 lightDirection = normalize(light.position - wsPosition.xyz);
      float diffuseIntensity = dot(wsNormals.xyz, lightDirection);
      totalDiffuseIntensity +=
          light.intensity * diffuseIntensity / (lightDist * lightDist);
    }
  }
  totalDiffuseIntensity /= lightCount;
  vec3 diffuse = diffuseColor * totalDiffuseIntensity;

  color = vec4(ambient + diffuse, 1.0);
}
