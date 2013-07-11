
Gpu = require '../lib/gpu'


class Chart
  constructor: (opts) ->
    @opts = $.extend true, { }, { name: 'chart', width: 800, height: 500, margin: { top: 20, right: 20, bottom: 30, left: 60 } }, opts
    
    @margin = @opts.margin
    @width = @opts.width - @margin.left - @margin.right
    @height = @opts.height - @margin.top - @margin.bottom
    @parent = @opts.parent
    @callback = @opts.callback
    
    @period = null
    
    @svg = d3.select(".charts")
      .append('div')
        .attr('class', "#{ @opts.name } chart")
      .append('svg')
        .attr('width', @width + @margin.left + @margin.right)
        .attr('height', @height + @margin.top + @margin.bottom)
    
    @svg.append('defs').append('clipPath')
        .attr('id', 'clip')
      .append('rect')
        .attr('width', @width)
        .attr('height', @height)
        .attr('x', @margin.left)
        .attr('y', @margin.top)
    
    if @opts.title
      @svg.append('text')
        .attr('x', @margin.left + @width / 2)
        .attr('y', @margin.top)
        .attr('text-anchor', 'middle')
        .style('font-size', '16px')
        .text @opts.title
    
    @svg.append('g')
      .attr('class', 'y axis')
      .attr('transform', "translate(#{ @margin.left }, #{ @margin.top })")
    
    @svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(#{ @margin.left }, #{ @height + @margin.top })")
    
    @svg.append('g')
      .attr('class', 'chart-region')
      .attr('transform', "translate(#{ @margin.left }, #{ @margin.top })")
      .attr('clip', 'url(#clip)')
    
    if @parent
      @rawData = @parent.rawData
      @data = @parent.data
      @render()
      @callback? @
    else
      @gpu = new Gpu()
      @loadData()
  
  
  loadData: =>
    d3.csv 'lcs_0.txt', (d, i) ->
      @minX or= +d.x
      
      { x: +d.x - @minX, y: +d.y }
    , (e, rows) =>
      @rawData = rows
      
      # Create two arrays (x and y)
      
      xArr = new Float32Array( @rawData.map( (d) -> return d.x ) )
      yArr = new Float32Array( @rawData.map( (d) -> return d.y ) )
      @gpu.loadData(xArr, yArr)
      
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
    @yScale(d.y)
  
  smooth: =>
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
  
  brushed: =>
    if @brush.empty()
      xExtent = d3.extent @parent.data, (d) -> d.x
      @parent.xScale.domain xExtent
    else
      @parent.xScale.domain @brush.extent()
    console.log @brush.extent()
    
    chartRegion = @parent.svg.select('.chart-region').selectAll('.dot')
      .data(@parent.data)
    
    chartRegion.enter().append('circle')
      .attr('class', 'dot')
      .attr('r', 2.0)
      .attr('cx', @parent.x)
      .attr('cy', @parent.y)
    
    chartRegion.attr('class', 'dot')
      .attr('cx', @parent.x)
      .attr('cy', @parent.y)
    
    @parent.svg.select('.x.axis').call d3.svg.axis().scale(@parent.xScale).orient('bottom')
  
  render: =>
    xExtent = d3.extent @data, (d) -> d.x
    yExtent = d3.extent @data, (d) -> d.y
    xExtent[1] = @period if @period
    
    @xScale = d3.scale.linear().range([0, @width]).domain xExtent
    @yScale = d3.scale.linear().range([@height, 0]).domain yExtent
    
    if @opts.zoomable and @parent
      @brush = d3.svg.brush()
        .x(@.xScale)
        .on 'brush', @brushed
      
      @svg.select('.chart-region')
        .call(@brush)
        .selectAll('rect')
          .attr('y', 0)
          .attr('height', @height)
    
    @svg.select('.y.axis').call d3.svg.axis().scale(@yScale).orient('left')
    @svg.select('.x.axis').call d3.svg.axis().scale(@xScale).orient('bottom')
    
    chartRegion = @svg.select('.chart-region').selectAll('.dot')
      .data(@data)
    
    chartRegion.enter().append('circle')
      .attr('class', 'dot')
      .attr('r', 2.0)
      .attr('cx', @x)
      .attr('cy', @y)
    
    chartRegion.attr('class', 'dot')
      .attr('cx', @x)
      .attr('cy', @y)

module.exports = Chart
