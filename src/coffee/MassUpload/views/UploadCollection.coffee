define [ 'backbone', 'underscore', './humanReadableSize' ], (Backbone, _, humanReadableSize) ->
  progressToText = (progress) ->
    "#{humanReadableSize(progress.loaded)} / #{humanReadableSize(progress.total)}"

  uploadToStatusAndMessage = (upload) ->
    if upload.get('deleting')
      status: 'deleting'
      message: 'Deleting…'
    else if !upload.get('file')? && !upload.isFullyUploaded()
      status: 'must-reselect'
      message: 'Drag the file here again or delete it'
    else if upload.get('error')
      status: 'error'
      message: 'Retry this file or delete it'
    else if upload.get('uploading')
      status: 'uploading'
      message: 'Uploading…'
    else if upload.isFullyUploaded()
      status: 'uploaded'
      message: ''
    else
      status: 'waiting'
      message: ''

  # Given a <li> element, returns:
  #
  # * li: the li element
  # * progress: the <progress> bar
  # * text: the progress-bar text
  # * size: the size text
  # * message: the message
  #
  # The stylesheet determines whether these are visible; this View ensures
  # their contents are valid.
  liToEls = (li) ->
    $li = Backbone.$(li)
    li: $li[0] # in case li is actually a jQuery object
    progress: $li.find('progress')[0]
    text: $li.find('.text')[0]
    message: $li.find('.message')[0]
    size: $li.find('.size')[0]

  # Shows all files we want to be on the server
  Backbone.View.extend
    className: 'upload-collection'

    events:
      'click .retry': '_onRetry'
      'click .delete': '_onDelete'
      'change input': '_onSelectFiles'
      'dragover': '_onDragover'
      'drop': '_onDrop'

    template: _.template("""
      <ul class="uploads">
        <%= collection.map(renderUpload).join('') %>
      </ul>
      <div class="upload-prompt">
        <button>
          <h3>Select files to upload</h3>
          <h4>Or drag and drop files here</h4>
        </button>
        <input type="file" class="invisible-file-input" multiple="multiple" />
      </div>
    """)

    uploadTemplate: _.template("""
      <li class="<%= status %>" data-id="<%- upload.id %>">
        <a href="#" class="delete">Delete</a>
        <a href="#" class="retry">Retry</a>
        <h3><%- upload.id %></h3>
        <div class="status">
          <progress value="<%= progress.loaded %>" max="<%= progress.total %>"></progress>
          <span class="text"><%= humanReadableSize(progress.loaded) %> / <%= humanReadableSize(progress.total) %></span>
          <span class="size"><%= humanReadableSize(progress.total) %></span>
          <span class="message"><%- message %></span>
        </div>
      </li>
    """)

    initialize: ->
      throw 'Must specify collection, an UploadCollection' if !@collection?

      @listenTo(@collection, 'change', @_onChange)
      @listenTo(@collection, 'add', @_onAdd)
      @listenTo(@collection, 'remove', @_onRemove)
      @listenTo(@collection, 'reset', @render)

      @render()

    _renderUpload: (upload) ->
      statusAndMessage = uploadToStatusAndMessage(upload)

      @uploadTemplate
        upload: upload
        status: statusAndMessage.status
        message: statusAndMessage.message
        error: upload.get('error')
        progress: upload.getProgress()
        humanReadableSize: humanReadableSize

    _onAdd: (upload, collection, options) ->
      html = @_renderUpload(upload)
      $li = Backbone.$(html)
      @els[upload.id] = liToEls($li)

      lis = @ul.childNodes

      index = options?.index || lis.length

      if index >= lis.length
        @ul.appendChild($li[0])
      else
        laterElement = @ul.childNodes[index]
        @ul.insertBefore($li[0], laterElement)

      undefined

    _onRemove: (upload) ->
      id = upload.id
      els = @els[id]
      throw 'Element does not exist' if !els?

      @ul.removeChild(els.li)
      delete @els[id]

      undefined

    _onChange: (upload) ->
      id = upload.id
      els = @els[id]

      if els?
        progress = upload.getProgress()
        statusAndMessage = uploadToStatusAndMessage(upload)

        els.progress.value = progress.loaded
        els.progress.max = progress.total
        els.text.firstChild.data = progressToText(progress)
        els.size.firstChild.data = humanReadableSize(progress.total)
        Backbone.$(els.message).text(statusAndMessage.message)
        els.li.className = statusAndMessage.status

    render: ->
      html = @template
        collection: @collection
        renderUpload: (upload) => @_renderUpload(upload)
        humanReadableSize: humanReadableSize

      @$el.html(html)
      @ul = @$el.children('ul.uploads')[0]

      els = @els = {} # hash of id to { li, progress, text, size, message }
      @$el.find('ul.uploads>li').each (li) ->
        id = li.getAttribute('data-id')
        els[id] = liToEls(li)

      this

    _onDragover: (e) ->
      e.preventDefault() # prevent browser default action

    _onDrop: (e) ->
      e.preventDefault()
      files = e.originalEvent?.dataTransfer?.files
      if files?.length
        @trigger('add-files', files)

    _eventToUpload: (e) ->
      id = Backbone.$(e.target).closest('[data-id]').attr('data-id')
      @collection.get(id)

    _onRetry: (e) ->
      e.preventDefault()
      upload = @_eventToUpload(e)
      @trigger('retry-upload', upload)

    _onDelete: (e) ->
      e.preventDefault()
      upload = @_eventToUpload(e)
      @trigger('remove-upload', upload)

    _onSelectFiles: (e) ->
      e.preventDefault()
      input = e.target
      files = input.files
      @trigger('add-files', files)
      input.value = '' # unset input.files
