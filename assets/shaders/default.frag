#version 330

uniform sampler2D diffuseTex;
uniform int hasDiffuseTex;

uniform vec3 ambient;
uniform vec3 diffuse;
uniform vec3 specular;
uniform float specularExponent;

in vec2 texCoordsFrag;
in vec4 wsNormals;

out vec4 color;

void main() {
  color = texture(diffuseTex, vec2(texCoordsFrag.x, 1.0 - texCoordsFrag.y));
}
