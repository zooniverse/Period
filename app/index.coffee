require 'jqueryify'
require 'd3/d3'
Home = require './controllers/home'

$ ->
  window.home = new Home
