define [ 'backbone' ], (Backbone) ->
  Backbone.Model.extend
    defaults:
      loaded: 0
      total: 0

    initialize: ->
      collection = @get('collection')
      throw 'Must initialize UploadProgress with `collection`, an UploadCollection' if !collection?

      adjust = (dLoaded, dTotal) =>
        @set
          loaded: @get('loaded') + dLoaded
          total: @get('total') + dTotal
        undefined

      cidToLastKnownProgress = {}

      add = (model) ->
        progress = model.getProgress()
        adjust(progress.loaded, progress.total)
        cidToLastKnownProgress[model.cid] = progress
      remove = (model) ->
        progress = cidToLastKnownProgress[model.cid]
        adjust(-progress.loaded, -progress.total)
        delete cidToLastKnownProgress[model.cid]
      change = (model) ->
        oldProgress = cidToLastKnownProgress[model.cid]
        if oldProgress? # if !oldProgress? there is a race; it is forthcoming...
          newProgress = model.getProgress()
          adjust(newProgress.loaded - oldProgress.loaded, newProgress.total - oldProgress.total)
          cidToLastKnownProgress[model.cid] = newProgress
      reset = =>
        cidToLastKnownProgress = {}
        progress = { loaded: 0, total: 0 }
        @get('collection').each (model) ->
          modelProgress = model.getProgress()
          cidToLastKnownProgress[model.cid] = modelProgress
          progress.loaded += modelProgress.loaded
          progress.total += modelProgress.total
        @set(progress)

      events =
        add: add
        remove: remove
        change: change
        reset: reset

      for eventName, callback of events
        @listenTo(collection, eventName, callback)

      reset()

      undefined
