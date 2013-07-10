Chart = require '../lib/chart'
VariableSlider = require '../lib/variable_slider'

class Home
  constructor: ->
    @overviewChart = new Chart width: 400, height: 250, name: 'overview'
    @primaryChart = new Chart name: 'primary'
    
    @periodSlider = new VariableSlider name: 'period', label: 'Period', callback: (value) =>
      @primaryChart.period = value
      @primaryChart.render()
    
    @smoothingSlider = new VariableSlider name: 'smoothing', label: 'Smoothing Window', min: 0.1, callback: (value) =>
      @primaryChart.smoothing = value
      @primaryChart.smooth()
      @primaryChart.render()

module.exports = Home
