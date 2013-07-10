Chart = require '../lib/chart'
VariableSlider = require '../lib/variable_slider'

class Home
  constructor: (opts = { }) ->
    @primaryChart = new Chart $.extend true, { }, opts, name: 'primary-chart'
    
    @periodSlider = new VariableSlider name: 'period', label: 'Period', callback: (value) =>
      @primaryChart.period = value
      @primaryChart.render()
    
    @smoothingSlider = new VariableSlider name: 'smoothing', label: 'Smoothing Window', min: 0.1, callback: (value) =>
      @primaryChart.smoothing = value
      @primaryChart.smooth()
      @primaryChart.render()

module.exports = Home
