
Shaders =
  
  vertex: [
    "precision mediump float;"
    
    "attribute vec3 aVertexPosition;"
    "attribute vec4 aVertexColor;"
    
    "uniform mat4 uMVMatrix;"
    "uniform mat4 uPMatrix;"
    
    "varying vec4 backColor;"
    
    "void main() {"
      "vec4 pos = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);"
      "backColor = aVertexColor;"
      
      "gl_Position = pos;"
    "}"
  ].join("\n")
  
  fragment: [
    "precision mediump float;"
    
    "varying vec4 backColor;"
    
    "void main() {"
      "gl_FragColor = backColor;"
    "}"
  ].join("\n")


module.exports = Shaders