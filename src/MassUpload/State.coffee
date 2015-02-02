module.exports = class State
  constructor: (attrs) ->
    attrs ?= {}

    @loaded = attrs.loaded ? 0
    @total = attrs.total ? 0
    @status = attrs.status ? 'waiting'
    @errors = attrs.errors ? []

  _extend: (attrs) ->
    new State
      loaded: attrs.loaded ? @loaded
      total: attrs.total ? @total
      status: attrs.status ? @status
      errors: attrs.errors ? @errors

  # Returns whether uploading is complete.
  #
  # Requirements:
  #
  # * Total bytes must be greater than 0
  # * Total bytes must all have been uploaded
  # * There must be no errors
  # * There must be no ongoing communication with the server
  isComplete: ->
    @total &&
      @loaded == @total &&
      @status == 'waiting' &&
      !@errors.length &&
      true || false

  # Returns a State with a different total
  withTotal: (total) ->
    @_extend(total: total)

  # Returns a State with a different loaded
  withLoaded: (loaded) ->
    @_extend(loaded: loaded)

  # Returns a State with a different status
  #
  # Valid statuses:
  #
  # * `listing`: fetching list from the server
  # * `uploading`: uploading a file to the server
  # * `waiting`: not communicating with the server
  withStatus: (status) ->
    @_extend(status: status)

  # Returns a State with an error added to the list of errors
  withAnError: (error) ->
    newErrors = @errors.slice(0)
    newErrors.push(error)
    @_extend(errors: newErrors)

  # Returns a State with an error removed from the list of errors
  withoutAnError: (error) ->
    newErrors = @errors.slice(0)
    index = newErrors.indexOf(error)
    newErrors.splice(index, 1)
    @_extend(errors: newErrors)
