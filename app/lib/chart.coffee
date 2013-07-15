Gpu = require '../lib/gpu'

class Chart
  constructor: (opts) ->
    @opts = $.extend true, { }, { container: '.charts', name: 'chart', width: 800, height: 500, margin: { top: 20, right: 20, bottom: 30, left: 60 } }, opts
    
    @margin = @opts.margin
    @width = @opts.width - @margin.left - @margin.right
    @height = @opts.height - @margin.top - @margin.bottom
    @parent = @opts.parent
    @callback = @opts.callback
    
    @brushing = false
    @period = null
    
    @svg = d3.select(@opts.container)
      .append('div')
        .attr('class', "#{ @opts.name } chart")
      .append('svg')
        .attr('xmlns', 'http://www.w3.org/2000/svg')
        .attr('version', '1.1')
        .attr('viewBox', "0 0 #{ @opts.width } #{ @opts.height }")
        .attr('width', @opts.width)
        .attr('height', @opts.height)
      .append('g')
        .attr('transform', "translate(#{ @margin.left }, #{ @margin.top })")
    
    if @opts.name is 'primary'
      @svg.append('defs').append('clipPath')
          .attr('id', 'clip')
        .append('rect')
          .attr('transform', 'translate(0, 0)')
          .attr('width', @width)
          .attr('height', @height)
    
    if @opts.title
      @svg.append('text')
        .attr('x', @width / 2)
        .attr('y', 0)
        .attr('text-anchor', 'middle')
        .style('font-size', '16px')
        .text @opts.title
    
    @svg.append('g')
      .attr('class', 'y axis')
      .attr('transform', "translate(#{ 0 }, #{ 0 })")
    
    @svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(#{ 0 }, #{ @height })")
    
    @svg.append('g')
        .attr('class', 'chart-region')
        .attr('width', @width)
        .attr('height', @height)
        .attr('clip-path', 'url(#clip)')
      .append('path')
        .attr('class', 'fit-line')
        .attr('stroke-width', 3.0)
        .attr('stroke', '#049cdb')
        .attr('fill', 'transparent')
        .attr('opacity', 1.0)
    
    @colorize = false
    @colors = d3.scale.category20()
    
    if @parent
      @rawData = @parent.rawData
      @data = @parent.data
      @render()
      @callback? @
    else
      # @gpu = new Gpu()
      @loadData @opts.file
  
  
  loadData: (file) =>
    @minX = null
    
    d3.csv file, (d, i) ->
      @minX or= +d.x
      
      { x: +d.x - @minX, y: +d.y }
    , (e, rows) =>
      @rawData = rows
      
      # Create two arrays (x and y)
      
      # xArr = new Float32Array( @rawData.map( (d) -> return d.x ) )
      # yArr = new Float32Array( @rawData.map( (d) -> return d.y ) )
      # @gpu.loadData(xArr, yArr)
      
      @totalAvg = d3.median @rawData, (d) -> d.y
      @smooth()
      @render()
      @callback? @
  
  x: (d) =>
    if @period
      @xScale d.x % @period
    else
      @xScale d.x
  
  y: (d) =>
    @yScale d.y
  
  dataInView: =>
    inView = []
    [min, max] = @xScale.domain()
    for datum in @data
      if @period
        d = x: datum.x % @period, y: datum.y
        
        if d.x >= min and d.x <= max
          inView.push d
      else
        return inView if datum.x > max
        if datum.x >= min and datum.x <= max
          inView.push datum
    
    inView.sort (a, b) -> if a.x < b.x then -1 else 1
  
  drawFit: =>
    data = @dataInView()
    fit = Gauss.fit data
    [min, max] = @xScale.domain()
    @fitData = []
    for point in data
      @fitData.push x: point.x, y: Gauss.model(fit, point.x - min)[0]
    
    fitLine = d3.svg.line().x(@x).y @y
    @svg.select('.fit-line').attr 'd', fitLine(@fitData)
  
  smooth: =>
    if @smoothing
      @data = []
      
      for d in @rawData
        min = d.x - @smoothing / 2
        max = d.x + @smoothing / 2
        sum = 0
        count = 0
        
        for p in @rawData
          break if p.x > max
          if p.x >= min and p.x <= max
            sum += p.y
            count++
        
        avg = sum / count
        @data.push
          x: d.x
          y: @totalAvg * d.y / avg
    else
      @data = $.extend true, [], @rawData
  
  brushed: =>
    if @brush.empty()
      @brushing = false
      @parent.render()
    else
      @brushing = true
      @parent.xScale.domain @brush.extent()
    
    @parent.plot()
    @parent.svg.select('.x.axis').call d3.svg.axis().scale(@parent.xScale).orient('bottom')
  
  plot: =>
    chartRegion = @svg.select('.chart-region').selectAll('.dot')
      .data(@data)
    
    chartRegion.enter().append('rect')
      .attr('class', 'dot')
      .attr('width', 2)
      .attr('height', 2)
      .attr('x', @x)
      .attr('y', @y)
    
    dot = chartRegion.attr('class', 'dot')
      .attr('x', @x)
      .attr('y', @y)
    
    if @colorize
      dot.style 'fill', (d, i) =>
          if @period
            @colors Math.floor(d.x / @period)
          else
            'black'
  
  render: =>
    xExtent = d3.extent @data, (d) -> d.x
    xExtent[1] = @period if @period
    yExtent = d3.extent @data, (d) -> d.y
    
    @xScale = d3.scale.linear().range([0, @width]).domain xExtent
    @brush?.x @xScale
    @yScale = d3.scale.linear().range([@height, 0]).domain yExtent
    
    if !@brush and @opts.zoomable and @parent
      @brush = d3.svg.brush()
        .x(@xScale)
        .on 'brush', @brushed
      
      @svg.select('.chart-region')
        .call(@brush)
        .selectAll('rect.background,rect.extent,.resize rect')
          .attr('y', 0)
          .attr('height', @height)
    
    @svg.select('.y.axis').call d3.svg.axis().scale(@yScale).orient('left')
    @svg.select('.x.axis').call d3.svg.axis().scale(@xScale).orient('bottom')
    
    if @brushing
      @plot()
      @brushed()
    else
      @plot()

module.exports = Chart
