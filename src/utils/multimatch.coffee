
import {minimatch} from 'minimatch'

export default (list, patterns, options={}) ->
  list = [list] unless Array.isArray list
  patterns = [patterns] unless Array.isArray patterns
  for el in list
    continue unless patterns.some (pattern) ->
      minimatch el, pattern, options
    el
