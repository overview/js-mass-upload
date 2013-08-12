define [ 'backbone', './upload' ], (Backbone, Upload) ->
  Backbone.Collection.extend
    model: Upload
