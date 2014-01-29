define [ 'backbone' ], (Backbone) ->
  # Listens to an UploadCollection and updates its `loaded` and `total`
  # attributes.
  Backbone.Model.extend
    defaults:
      loaded: 0
      total: 0

    initialize: ->
      collection = @get('uploadCollection')
      throw 'Must initialize UploadProgress with `uploadCollection`, an UploadCollection' if !collection?

      @_idToLastKnownProgress = {}

      @_updateAndStartListening()

    _adjust: (dLoaded, dTotal) ->
      @set
        loaded: @get('loaded') + dLoaded
        total: @get('total') + dTotal

    add: (model) ->
      progress = model.getProgress()
      @_adjust(progress.loaded, progress.total)
      @_idToLastKnownProgress[model.id] = progress

    reset: (collection) ->
      idToLastKnownProgress = @_idToLastKnownProgress = {}
      loaded = 0
      total = 0
      for model in collection.models
        progress = model.getProgress()
        idToLastKnownProgress[model.id] = progress
        loaded += progress.loaded
        total += progress.total
      @set(loaded: loaded, total: total)

    remove: (model) ->
      progress = model.getProgress()
      @_adjust(-progress.loaded, -progress.total)
      @_idToLastKnownProgress[model.id] = progress

    change: (model) ->
      oldProgress = @_idToLastKnownProgress[model.id]
      if oldProgress? # if there's no oldProgress, then an 'add' is coming
        newProgress = model.getProgress()
        @_adjust(newProgress.loaded - oldProgress.loaded, newProgress.total - oldProgress.total)
        @_idToLastKnownProgress[model.id] = newProgress

    _updateAndStartListening: ->
      collection = @get('uploadCollection')

      for event in [ 'add', 'remove', 'change', 'reset' ]
        @listenTo(collection, event, @[event])

      @reset(collection)

      undefined

    # Stops listening for the duration of the callback.
    #
    # Call this when you know you'll be making large changes to the collection.
    # It will remove Backbone event handlers, so it will never be called.
    inBatch: (callback) ->
      @stopListening(@get('uploadCollection'))
      try
        callback()
      finally
        @_updateAndStartListening()
