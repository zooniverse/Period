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
    
    $(document.body).on 'change', '.slider', (ev) =>
      ev.preventDefault()
      slider = $(ev.target)
      variable = slider.data 'variable'
      val = slider.val()
      @[variable] = val
      input = slider.siblings('.slider-value').val val
      @smooth() if variable is 'smoothing'
      @render()
    
    $(document.body).on 'change', '.slider-value', (ev) =>
      ev.preventDefault()
      input = $(ev.target)
      variable = input.data 'variable'
      val = input.val()
      @[variable] = val
      slider = input.siblings('.slider').val val
      input.val slider.val()
      @smooth() if variable is 'smoothing'
      @render()
    
    $(document.body).on 'click', '.slider-reset', (ev) =>
      ev.preventDefault()
      button = $(ev.target)
      variable = button.data 'variable'
      @[variable] = null
      button.siblings('.slider').val ''
      button.siblings('.slider-value').val ''
      @smooth() if variable is 'smoothing'
      @render()
    
    @loadData()
    $('.variable-sliders').append require('../views/variable_slider') name: 'period', label: 'Period'
    $('.variable-sliders').append require('../views/variable_slider') name: 'smoothing', label: 'Smoothing Window', min: 0.1
  
  loadData: =>
    d3.csv 'lcs_0.txt', (d, i) ->
      @minX or= +d.x
      
      { x: +d.x - @minX, y: +d.y }
    , (e, rows) =>
      @rawData = rows
      @smooth()
      @render()
  
  x: (d) =>
    if @period
      @xScale d.x % @period
    else
      @xScale d.x
  
  y: (d) =>
    @yScale(d.y)
  
  smooth: =>
    if @smoothing
      totalAvg = d3.median @rawData, (d) -> d.y
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
          y: totalAvg * d.y / avg
    else
      @data = $.extend true, [], @rawData
  
  render: =>
    xExtent = d3.extent @data, (d) -> d.x
    yExtent = d3.extent @data, (d) -> d.y
    xExtent[1] = @period if @period
    
    @xScale = d3.scale.linear().range([0, @width]).domain xExtent
    @yScale = d3.scale.linear().range([@height, 0]).domain yExtent
    
    @svg.select('.y.axis').call d3.svg.axis().scale(@yScale).orient('left')
    @svg.select('.x.axis').call d3.svg.axis().scale(@xScale).orient('bottom')
    
    dots = @svg.select('.dots').selectAll('.dot')
      .data(@data)
    
    dots.enter().append('circle')
      .attr('class', 'dot')
      .attr('r', 2.0)
      .attr('cx', @x)
      .attr('cy', @y)
    
    dots.attr('class', 'dot')
      .attr('cx', @x)
      .attr('cy', @y)


module.exports = Home
