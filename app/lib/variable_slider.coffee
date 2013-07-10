class VariableSlider
  constructor: (opts) ->
    defaults =
      el: '.variable-sliders',
      name: 'variable',
      label: 'Variable'
      min: 1
      max: 45
      step: 0.01
      callback: null
    
    @opts = $.extend true, { }, defaults, opts
    
    $(@opts.el).append require('../views/variable_slider') @opts
    
    $(".slider[data-variable='#{ @opts.name }']").change (ev) =>
      ev.preventDefault()
      slider = $(ev.target)
      variable = slider.data 'variable'
      val = slider.val()
      input = slider.siblings('.slider-value').val val
      @opts.callback? val
    
    $(".slider-value[data-variable='#{ @opts.name }']").change (ev) =>
      ev.preventDefault()
      input = $(ev.target)
      variable = input.data 'variable'
      val = input.val()
      @chart[variable] = val
      slider = input.siblings('.slider').val val
      input.val slider.val()
      @opts.callback? val
    
    $(".slider-reset[data-variable='#{ @opts.name }']").click (ev) =>
      ev.preventDefault()
      button = $(ev.target)
      variable = button.data 'variable'
      button.siblings('.slider').val ''
      button.siblings('.slider-value').val ''
      @opts.callback? null

module.exports = VariableSlider
