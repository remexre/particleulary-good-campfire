#version 330

uniform sampler2D tex;
in vec2 texCoordsFrag;

out vec4 color;

void main() { color = texture(tex, texCoordsFrag); }
