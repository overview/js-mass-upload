define [ 'backbone', 'underscore', './humanReadableSize' ], (Backbone, _, humanReadableSize) ->
  # Shows a progress bar (must be extended)
  Backbone.View.extend
    className: 'list-files-progress'

    massUploadProperty: ''

    preamble: ''

    initialize: ->
      throw 'Must specify model, a MassUpload object' if !@model?
      @listenTo(@model, "change:#{@massUploadProperty}", => @_updateProgress())
      @render()

    template: _.template("""
      <%= preamble %>
      <progress value="<%= progress.loaded %>" max="<%= progress.total %>"></progress>
      <span class="text"><%= humanReadableSize(progress.loaded) %> / <%= humanReadableSize(progress.total) %></span>
    """)

    getProgress: ->
      @model.get(@massUploadProperty) || { loaded: 0, total: 0 }

    render: ->
      progress = @getProgress()
      html = @template
        preamble: @preamble
        progress: progress
        humanReadableSize: humanReadableSize

      @$el.html(html)
      @progressEl = @$el.find('progress')[0]
      @textEl = @$el.find('.text')[0]

    _updateProgress: ->
      progress = @getProgress()
      @progressEl.value = progress.loaded
      @progressEl.max = progress.total
      Backbone.$(@textEl).text("#{humanReadableSize(progress.loaded)} / #{humanReadableSize(progress.total)}")
      undefined
