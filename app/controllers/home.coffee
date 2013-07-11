Chart = require '../lib/chart'
VariableSlider = require '../lib/variable_slider'

class Home
  constructor: ->
    @primaryChart = new Chart name: 'primary', callback: (chart) =>
      @overviewChart = new Chart width: 400, height: 250, name: 'overview', parent: chart, title: 'Original'
      @zoomChart = new Chart width: 400, height: 250, name: 'zoom', zoomable: true, parent: chart, title: 'Zoom Context'
    
    @periodSlider = new VariableSlider name: 'period', label: 'Period', callback: (value) =>
      @primaryChart.period = @zoomChart.period = value
      @zoomChart.data = @primaryChart.data
      @primaryChart.render()
      @zoomChart.render()
    
    @smoothingSlider = new VariableSlider name: 'smoothing', label: 'Smoothing Window', min: 0.1, callback: (value) =>
      @primaryChart.smoothing = @zoomChart.smoothing = value
      @primaryChart.smooth()
      @zoomChart.data = @primaryChart.data
      @primaryChart.render()
      @zoomChart.render()

module.exports = Home
