
vertex = [
  "attribute vec2 a_position;"
  "attribute vec2 a_textureCoord;"
  
  "uniform vec2 u_offset;"
  "uniform float u_scale;"
  
  "varying vec2 v_textureCoord;"
  
  "void main() {"
    "vec2 position = a_position + u_offset;"
    "position = position * u_scale;"
    "gl_Position = vec4(position, 0.0, 1.0);"
    
    "v_textureCoord = a_textureCoord;"
  "}"
].join("\n")

fragment = [
  "precision mediump float;"
  
  "uniform sampler2D uX;"
  "uniform sampler2D uY;"
  
  "varying vec2 v_textureCoord;"
  
  "void main() {"
      "vec4 x = texture2D(uX, v_textureCoord);"
      "vec4 y = texture2D(uY, v_textureCoord);"
      
      "gl_FragColor = x;"
  "}"
].join("\n")


class Gpu
  
  
  _loadShader: (gl, source, type) ->
    
    shader = gl.createShader(type)
    gl.shaderSource(shader, source)
    gl.compileShader(shader)
    
    compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS)
    unless compiled
      lastError = gl.getShaderInfoLog(shader)
      throw "Error compiling shader #{shader}: #{lastError}"
      gl.deleteShader(shader)
      return null
    
    return shader
  
  _createProgram: (gl, vertexShader, fragmentShader) ->
    vertexShader = @_loadShader(gl, vertexShader, gl.VERTEX_SHADER)
    fragmentShader = @_loadShader(gl, fragmentShader, gl.FRAGMENT_SHADER)
    
    program = gl.createProgram()
    
    gl.attachShader(program, vertexShader)
    gl.attachShader(program, fragmentShader)
    gl.linkProgram(program)
    
    linked = gl.getProgramParameter(program, gl.LINK_STATUS)
    unless linked
      throw "Error in program linking: #{gl.getProgramInfoLog(program)}"
      gl.deleteProgram(program)
      return null
    
    gl.useProgram(program)
    return program
  
  
  constructor: ->
    @hasData = false
    
    # TODO: WebGL and extension detection
    @canvas = document.querySelector("#gpu")
    @gl = @canvas.getContext('webgl')
    @ext = @gl.getExtension('OES_texture_float')
    
    @program = @_createProgram(@gl, vertex, fragment)
    
    # Get attribute and uniform locations
    positionLocation  = @gl.getAttribLocation(@program, 'a_position')
    texCoordLocation  = @gl.getAttribLocation(@program, 'a_textureCoord')
    offsetLocation    = @gl.getUniformLocation(@program, 'u_offset')
    scaleLocation     = @gl.getUniformLocation(@program, 'u_scale')
    
    @gl.uniform2f(offsetLocation, 0, 0)
    @gl.uniform1f(scaleLocation, 1)
    
    # Create texture coordinate buffer
    texCoordBuffer = @gl.createBuffer()
    @gl.bindBuffer(@gl.ARRAY_BUFFER, texCoordBuffer)
    @gl.bufferData(
      @gl.ARRAY_BUFFER,
      new Float32Array([0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0]),
      @gl.STATIC_DRAW
    )
    @gl.enableVertexAttribArray(texCoordLocation)
    @gl.vertexAttribPointer(texCoordLocation, 2, @gl.FLOAT, false, 0, 0)
    
    buffer = @gl.createBuffer()
    @gl.bindBuffer(@gl.ARRAY_BUFFER, buffer)
    @gl.enableVertexAttribArray(positionLocation)
    @gl.vertexAttribPointer(positionLocation, 2, @gl.FLOAT, false, 0, 0)
  
  loadData: (x, y) ->
    return if @hasData
    @hasData = true
    
    @setTexture(0, x)
    @setTexture(1, y)
    
    @gl.activeTexture(@gl.TEXTURE0)
    location = @gl.getUniformLocation(@program, "uX")
    @gl.uniform1i(location, 0)
    
    @gl.activeTexture(@gl.TEXTURE1)
    location = @gl.getUniformLocation(@program, "uY")
    @gl.uniform1i(location, 1)
    @gldrawArrays(ctx.TRIANGLES, 0, 6)
    
  setTexture: (index, arr) ->
    
    @gl.activeTexture(@gl["TEXTURE#{index}"])
    texture = @gl.createTexture()
    @gl.bindTexture(@gl.TEXTURE_2D, texture)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.CLAMP_TO_EDGE)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.CLAMP_TO_EDGE)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.NEAREST)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.NEAREST)
    
    @gl.texImage2D(@gl.TEXTURE_2D, 0, @gl.LUMINANCE, arr.length, 1, 0, @gl.LUMINANCE, @gl.FLOAT, arr)
  
  smooth: (x, y) ->
    
    if @smoothing
      @data = []
      
      for d in @rawData
        min = d.x - @smoothing / 2
        max = d.x + @smoothing / 2
        sum = 0
        count = 0
        
        for p in @rawData when p.x >= min and p.x <= max
          sum += p.y
          count++
        
        avg = sum / count
        @data.push
          x: d.x
          y: @totalAvg * d.y / avg
    else
      @data = $.extend true, [], @rawData
  

module.exports = Gpu
