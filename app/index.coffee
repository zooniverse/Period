require 'jqueryify'
require './lib/jquery-ui-1.10.3.custom.min'
require 'd3/d3'
Home = require './controllers/home'

$ ->
  window.home = new Home
