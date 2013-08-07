define [], ->
  class Error
    constructor: (@failedCall, @failedCallArgument, @detail) ->
