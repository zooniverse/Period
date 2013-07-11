require 'jqueryify'
require 'd3/d3'
require './lib/optimize'
Home = require './controllers/home'

$ ->
  window.home = new Home
