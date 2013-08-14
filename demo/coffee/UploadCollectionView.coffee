define [ 'backbone', 'underscore', 'humanReadableSize' ], (Backbone, _, humanReadableSize) ->
  progressToText = (progress) ->
    "#{humanReadableSize(progress.loaded)} / #{humanReadableSize(progress.total)}"

  uploadToStatusAndMessage = (upload) ->
    if upload.get('deleting')
      status: 'deleting'
      message: 'Deleting…'
    if !upload.get('file')? && !upload.isFullyUploaded()
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
      'click .delete': '_onDelete'
      'dragover': '_onDragover'
      'drop': '_onDrop'

    template: _.template("""
      <ul class="uploads">
        <%= collection.map(renderUpload).join('') %>
      </ul>
    """)

    uploadTemplate: _.template("""
      <li class="<%= status %>" data-cid="<%- upload.cid %>">
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

      @listenTo(@collection, 'change', (model) => @_onChange(model))
      @listenTo(@collection, 'add', (model, collection, options) => @_onAdd(model, options.at))
      @listenTo(@collection, 'remove', (model) => @_onRemove(model))
      @listenTo(@collection, 'reset', => @render())

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

    _onAdd: (upload, index) ->
      html = @_renderUpload(upload)
      $li = Backbone.$(html)
      @els[upload.cid] = liToEls($li)

      lis = @ul.childNodes

      if index >= lis.length
        @ul.appendChild($li[0])
      else
        laterElement = @ul.childNodes[index]
        @ul.insertBefore($li[0], laterElement)

      undefined

    _onRemove: (upload) ->
      cid = upload.cid
      els = @els[cid]
      throw 'Element does not exist' if !els?

      @ul.removeChild(els.li)
      delete @els[cid]

      undefined

    _onChange: (upload) ->
      cid = upload.cid
      els = @els[cid]

      if els?
        progress = upload.getProgress()
        statusAndMessage = uploadToStatusAndMessage(upload)

        console.log(cid, upload.attributes, statusAndMessage.status, els)

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

      els = @els = {} # hash of cid to { li, progress, text, size, message }
      @$el.find('ul.uploads>li').each (li) ->
        cid = li.getAttribute('data-cid')
        els[cid] = liToEls(li)

      this

    _onDragover: (e) ->
      e.preventDefault() # prevent browser default action

    _onDrop: (e) ->
      e.preventDefault()
      files = e.originalEvent?.dataTransfer?.files
      console.log(files)
      if files?.length
        @trigger('add-files', files)

    _eventToUpload: (e) ->
      cid = Backbone.$(e.target).closest('[data-cid]').attr('data-cid')
      @collection.get(cid)

    _onRetry: (e) ->
      e.preventDefault()
      upload = @_eventToUpload(e)
      @trigger('retry-upload', upload)

    _onDelete: (e) ->
      e.preventDefault()
      upload = @_eventToUpload(e)
      @trigger('remove-upload', upload)
