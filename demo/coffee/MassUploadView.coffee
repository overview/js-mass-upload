define [ 'backbone', 'underscore' ], (Backbone, _) ->
  # Returns human-readable, brief byte size string.
  #
  # For instance:
  #
  # 1024 -> "1 kB"
  # 500 -> "500 B"
  # 700 -> "0.7 kB"
  humanReadableSize = (size) ->
    units = [
      'kB'
      'MB'
      'GB'
      'TB'
    ]
    s = "#{size} B"
    for unit in units
      size /= 1024
      if size <= 512
        s = "#{size.toFixed(1)} #{unit}"
        break
    s

  Backbone.View.extend
    className: 'mass-upload'

    events:
      'dragover': '_onDragover'
      'drop': '_onDrop'

    template: _.template("""
      <ul class="uploads">
        <%= massUpload.uploads.map(renderUpload).join('') %>
      </ul>
      <p class="status"><%- massUpload.get('status') %></p>
      <% if (massUpload.get('status') == 'listing-files') { %>
        <% var progress = massUpload.get('listFilesProgress'); %>
        <% if (progress) { %>
          <div class="listing-files-progress">
            Listing files from server:
            <progress value="<%= progress.loaded %>" max="<%= progress.total %>"></progress>
            <%= humanReadableSize(progress.loaded) %> / <%= humanReadableSize(progress.total) %>
          </div>
        <% } %>
      <% } %>
      <% if (massUpload.get('status') == 'uploading') { %>
        <% var progress = massUpload.get('uploadProgress'); %>
        <% if (progress) { %>
          <div class="global-progress">
            Uploading to server:
            <progress value="<%= progress.loaded %>" max="<%= progress.total %>"></progress>
            <%= humanReadableSize(progress.loaded) %> / <%= humanReadableSize(progress.total) %>
          </div>
        <% } %>
      <% } %>
    """)

    uploadTemplate: _.template("""
      <li class="upload <%= upload.get('uploading') ? 'uploading' : '' %> <%= upload.get('deleting') ? 'deleting' : '' %>" data-cid="<%- upload.cid %>">
        <div class="filename"><%- upload.id %></div>
        <% if (upload.get('uploading'))  { %>
          <div class="progress">
            <% var total = upload.get('file').size; %>
            <% var loaded = upload.get('fileInfo') && upload.get('fileInfo').loaded || 0; %>
            <progress value="<%= loaded %>" max="<%= total %>"></progress>
            <%= humanReadableSize(loaded) %> / <%= humanReadableSize(total) %>
          </div>
        <% } %>
      </li>
    """)

    initialize: ->
      @initialRender()

      @model.on('change', => @render())
      @model.uploads.on('change add remove', => @render())

    renderUpload: (upload) ->
      @uploadTemplate
        upload: upload
        humanReadableSize: humanReadableSize

    initialRender: ->
      html = @template
        massUpload: @model
        renderUpload: (upload) => @renderUpload(upload)
        humanReadableSize: humanReadableSize

      @$el.html(html)

    render: ->
      @$els = @initialRender()

    _onDragover: (e) ->
      e.preventDefault() # prevent browser default action

    _onDrop: (e) ->
      e.preventDefault()
      files = e.originalEvent?.dataTransfer?.files
      console.log(files)
      if files?.length
        @model.addFiles(files)
