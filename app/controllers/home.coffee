window.data = []

class Home
  constructor: (opts = { }) ->
    opts = $.extend true, { }, { width: 800, height: 500, margin: { top: 20, right: 20, bottom: 30, left: 60 } }, opts
    @margin = opts.margin
    @width = opts.width - @margin.left - @margin.right
    @height = opts.height - @margin.top - @margin.bottom
    @period = null
    
    @svg = d3.select('#app').append('svg')
      .attr('width', @width + @margin.left + @margin.right)
      .attr('height', @height + @margin.top + @margin.bottom)
    
    @svg.append('g')
      .attr('class', 'y axis')
      .attr('transform', "translate(#{ @margin.left }, #{ @margin.top })")
    
    @svg.append('g')
      .attr('class', 'x axis')
      .attr('transform', "translate(#{ @margin.left }, #{ @height + @margin.top })")
    
    @svg.append('g')
      .attr('class', 'dots')
      .attr('transform', "translate(#{ @margin.left }, #{ @margin.right })")
    
    $('.slider').slider
      min: 1
      max: 45
      step: 0.01
      slide: (ev, ui) =>
        $('.slider-label').text ui.value
        @period = ui.value
        @render()
    
    @loadData()
  
  loadData: =>
    d3.csv 'lcs_3.txt', (d, i) ->
      @minX or= +d.x
      
      { x: +d.x - @minX, y: +d.y }
    , (e, rows) =>
      window.data = rows
      @render()
  
  x: (d) =>
    if @period
      @xScale d.x % @period
    else
      @xScale d.x
  
  y: (d) =>
    @yScale(d.y)
  
  render: =>
    xExtent = d3.extent data, (d) -> d.x
    yExtent = d3.extent data, (d) -> d.y
    xExtent[1] = @period if @period
    
    @xScale = d3.scale.linear().range([0, @width]).domain xExtent
    @yScale = d3.scale.linear().range([@height, 0]).domain yExtent
    
    @svg.select('.y.axis').call d3.svg.axis().scale(@yScale).orient('left')
    @svg.select('.x.axis').call d3.svg.axis().scale(@xScale).orient('bottom')
    
    dots = @svg.select('.dots').selectAll('.dot')
      .data(data)
    
    dots.enter().append('circle')
      .attr('class', 'dot')
      .attr('r', 2.0)
      .attr('cx', @x)
      .attr('cy', @y)
    
    dots.attr('class', 'dot')
      .attr('cx', @x)
      .attr('cy', @y)


module.exports = Home
