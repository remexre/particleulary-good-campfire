#version 330

uniform sampler2D diffuseTex;
in vec2 texCoordsFrag;

out vec4 color;

void main() {
  color = texture(diffuseTex, vec2(texCoordsFrag.x, 1.0 - texCoordsFrag.y));
}
