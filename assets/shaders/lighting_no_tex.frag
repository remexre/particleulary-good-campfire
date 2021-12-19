#version 330

in vec4 wsNormals;

out vec4 color;

void main() { color = (wsNormals + vec4(1)) / 2; }
