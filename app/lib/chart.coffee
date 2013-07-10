
Gpu = require '../lib/gpu'


class Chart
  constructor: (opts) ->
    @opts = $.extend true, { }, { name: 'chart', width: 800, height: 500, margin: { top: 20, right: 20, bottom: 30, left: 60 } }, opts
    
    @margin = @opts.margin
    @width = @opts.width - @margin.left - @margin.right
    @height = @opts.height - @margin.top - @margin.bottom
    @callback = @opts.callback
    
    @period = null
    
    @svg = d3.select(".charts")
      .append('div')
        .attr('class', "#{ @opts.name } chart")
      .append('svg')
        .attr('width', @width + @margin.left + @margin.right)
        .attr('height', @height + @margin.top + @margin.bottom)
    
    if @opts.title
      @svg.append('text')
        .attr('x', @margin.left + @width / 2)
        .attr('y', @margin.top)
        .attr('text-anchor', 'middle')
        .style('font-size', '16px')
        .text @opts.title
    
    @svg.append('rect')
      .attr('class', 'overlay')
      .attr('width', @width)
      .attr('height', @height)
      .attr('transform', "translate(#{ @margin.left }, #{ @margin.top })")
    
    @svg.append('g')
      .attr('class', 'y axis')
      .attr('transform', "translate(#{ @margin.left }, #{ @margin.top })")
    
    @svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(#{ @margin.left }, #{ @height + @margin.top })")
    
    @svg.append('g')
      .attr('class', 'chart-region')
      .attr('transform', "translate(#{ @margin.left }, #{ @margin.right })")
    
    if @opts.parent
      @rawData = @opts.parent.rawData
      @data = @opts.parent.data
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
  
  zoom: =>
    console.log 'zooming'
    @svg.select('.y.axis').call d3.svg.axis().scale(@yScale).orient('left')
    @svg.select('.x.axis').call d3.svg.axis().scale(@xScale).orient('bottom')
    translation = "translate(#{ @margin.left + d3.event.translate[0] }, #{ @margin.right + d3.event.translate[1] })"
    scale = "scale(#{ d3.event.scale })"
    @svg.select('.chart-region').attr 'transform', "#{ translation }#{ scale }"
  
  render: =>
    xExtent = d3.extent @data, (d) -> d.x
    yExtent = d3.extent @data, (d) -> d.y
    xExtent[1] = @period if @period
    
    @xScale = d3.scale.linear().range([0, @width]).domain xExtent
    @yScale = d3.scale.linear().range([@height, 0]).domain yExtent
    
    if @opts.zoomable
      zoomBehavior = d3.behavior.zoom()
        .x(@xScale)
        .y(@yScale)
        .scaleExtent([1, 8])
        .on 'zoom', @zoom
      
      @svg.select('.overlay').call(zoomBehavior) if @opts.zoomable
    
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
