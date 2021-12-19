#version 330 core

uniform sampler2D diffuseTex;
uniform int hasDiffuseTex;

uniform vec3 materialAmbient;
uniform vec3 materialDiffuse;
uniform vec3 materialSpecular;
uniform float specularExponent;

in vec2 texCoordsFrag;
in vec4 wsNormals;

out vec4 color;

void main() {
  vec3 ambient = materialAmbient;
  vec3 diffuse = (hasDiffuseTex != 0) ? texture(diffuseTex, texCoordsFrag).rgb
                                      : materialDiffuse;
  vec3 specular = materialSpecular;

  color = vec4(diffuse, 1.0);
}
