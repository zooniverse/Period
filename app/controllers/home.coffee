Chart = require '../lib/chart'
VariableSlider = require '../lib/variable_slider'
window.Gauss = require '../lib/gauss'

class Home
  examples = {
    'RR Lyrae': ['kplr005299596-2011271113734_llc', 'kplr006070714-2011271113734_llc', 'kplr007988343-2011271113734_llc', 'kplr009591503-2011271113734_llc'],
    'Gamma Dor / Delta Scuti / Beta Cep': ['kplr002859567-2011271113734_llc', 'kplr007304385-2011271113734_llc', 'kplr010974032-2011271113734_llc', 'kplr012153021-2011271113734_llc'],
    'EBs - Detached': ['kplr001026957-2011271113734_llc', 'kplr002305372-2011271113734_llc'],
    'EBs - Semi detached': ['kplr005120793-2011271113734_llc', 'kplr005809827-2011271113734_llc'],
    'EBs - Overcontact': ['kplr007839027-2011271113734_llc', 'kplr007889628-2011271113734_llc'],
    'Ellipsoidal': ['kplr010123627-2011271113734_llc', 'kplr010148799-2011271113734_llc']
  }
  
  constructor: ->
    @primaryChart = new Chart file: 'lcs_0.txt', name: 'primary', callback: (chart) =>
      @overviewChart = new Chart width: 400, height: 250, name: 'overview', parent: chart, title: 'Original'
      @zoomChart = new Chart width: 400, height: 250, name: 'zoom', zoomable: true, parent: chart, title: 'Zoom Context'
    
    @periodSlider = new VariableSlider name: 'period', label: 'Period', step: 0.001, callback: (value) =>
      @primaryChart.period = @zoomChart.period = value
      @zoomChart.data = @primaryChart.data
      @primaryChart.render()
      @zoomChart.render()
    
    @smoothingSlider = new VariableSlider name: 'smoothing', label: 'Smoothing Window', min: 0.01, step: 0.001, callback: (value) =>
      @primaryChart.smoothing = @zoomChart.smoothing = value
      @primaryChart.smooth()
      @zoomChart.data = @primaryChart.data
      @primaryChart.render()
      @zoomChart.render()
    
    i = 0
    for type, list of examples
      $('.examples').append $("<div class='example' name='#{ type }'><h2 class='type'>#{ type }</span></h2>")
      
      for file in list
        new Chart file: "examples/#{ file }.csv", container: ".examples [name='#{ type }']", name: "example-#{ i += 1}", title: file, width: 320, height: 200
      
      

module.exports = Home
