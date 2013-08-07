MassUpload
==========

Lets the user upload lots of huge files.

Why?
----

There are lots of libraries that do this already, but they're missing a key question: how do we upload a file to the server? This is important: as you go beyond tiny files, `multipart/form-data` just won't cut it.

MassUpload lets the developer decide. So you, being a clever developer, can upload several gigabytes' worth of data and resume when interrupted.

Usage
-----

First, include the library. You may use RequireJS:

```javascript
require([ 'path/to/mass-upload' ], function(MassUpload) { ... });
```

Or, you can go the old-fashioned route in your HTML:

```html
<script src="path/to/mass-upload.no-require.js"></script>
```

Now you'll need to implement a few asynchronous functions. The return values are ignored; instead, these functions are expected to call the appropriate callbacks that are passed to them.

```javascript
var app = new MassUpload({
  doListFiles: function(progress, success, error) { ... },
  doUploadFile: function(file, progress, success, error) { ... },
  doDeleteFile: function(fileInfo, success, error) { ... },
  onUploadConflictingFile: function(file, conflictingFileInfo, deleteFromServer, skip) { ... },
  onStateChanged: function(state, massUpload) { ... }
});

$('form#mass-upload').prepend(app.el);
```

Finally, write your UI. It may iterate over `MassUpload.uploads`, a list of files; `onStateChanged` will be called whenever the list changes (because the total size of the upload will change).

Broad ideas
-----------

If you're going to support resume (or even if you aren't but you want to keep yourself open to the possibility some day), then the user interface could get tricky: how do you get users to re-select the files they selected last time they were on this page?

The answer is to be transparent:

* Keep a list on the server of what the user has uploaded.
* Show that list to the user.
* Let the user edit that list, by deleting files or adding new files.

MassUpload does this.

Client-side API
---------------

You'll need to implement a few functions and pass them in the MassUpload app's constructor.

But first let's define some datatypes:

* `File`: See the [W3 File API](http://www.w3.org/TR/FileAPI/#dfn-file). This represents a file on the client side. The web browser creates this object.
* `ProgressEvent`: See the [W3 Progress Events API](http://www.w3.org/TR/progress-events/).
* `MassUpload`: an object containing:
    * `state` (a `State`)
    * `uploads` (an Array of `Upload` objects)
    * `deleteUpload(upload)`: deletes an upload
* `MassUpload.FileInfo`: depicts a file on the server. An object containing:
    * `name` (a `String`)
    * `lastModifiedDate` (a `Date`)
    * `total` (an integer `Number` depicting total size)
    * `loaded` (an integer `Number` less than or equal to `size`)
* `MassUpload.Upload`: depicts a single object which either *is* on the server or *should* be on the server. An object containing:
    * `file` (a `File`, if the user has selected this file on the client)
    * `fileInfo` (a `FileInfo`, if the file is on the server, either partially uploaded or completely uploaded)
    * `error` (an `Error` or `null`)
    * `isComplete()`: `true` iff `fileInfo.loaded === fileInfo.total`
* `MassUpload.State`: an immutable object containing:
    * `loaded` and `total` (integer `Number`s, like in a `ProgressEvent`)
    * `status` (`"listing"`, `"uploading"` or `"waiting"`)
    * `errors` (an Array of `Error` objects)
    * `isComplete()`: `true` iff `state === "waiting" && loaded === total && total > 0 && errors.length === 0`
* `MassUpload.Error`: an error that prevents this upload from going smoothly. Errors can be removed by retrying operations or removing the files that they apply to. They are immutable and contain:
    * `failedCall`: "listFiles", "uploadFile" or "deleteFile"
    * `failedCallArgument`: `undefined`, a `File` or a `FileInfo`, as appropriate
    * `detail`: a raw error object (you define what that should be; perhaps an `XMLHttpRequest`)

Got that? Great. Here's what you need to implement:

---

```javascript
function doListFiles(progress, success, error) { ... }
```

Lists files already uploaded to the server. Called when initializing.

* Calls `progress(progressEvent)`, where `progressEvent` is a `ProgressEvent`, during loading.
* Calls `success(data)`, where `data` is an `Array` of `FileInfo` objects, when loading is complete.
* Calls `error(detail)`, where `detail` contains the error's details (perhaps it's an `XMLHttpRequest`), if listing fails.

**Parameters**:

* `progress`: To be called during loading.
* `success`: To be called on success.
* `error`: To be called on error.

---

```javascript
function doUploadFile(file, progress, success, error) { ... }
```

Uploads a file to the server. Called asynchronously.

* Calls `progress(progressEvent)`, where `progressEvent` is a `ProgressEvent`, during loading.
* Calls `success()` when upload is complete.
* Calls `error(detail)`, where `detail` contains the error's details (perhaps it's an `XMLHttpRequest`), if the upload fails.

**Parameters**:

* `file`: A user-selected `File` which may or may not be partially uploaded to the server already.
* `progress`: To be called during upload.
* `success`: To be called on success.
* `error`: To be called on error.

**Returns**: a function that, when called, aborts the operation as soon as possible. (This function should asynchronously call `error('aborted')`.)

---

```javascript
function doDeleteFile(fileInfo, success, error) { ... }
```

Deletes a file from the server. Called asynchronously.

* Calls `success()` when delete has succeeded.
* Calls `error(detail)`, where `detail` contains the error's details (perhaps it's an `XMLHttpRequest`), if the delete fails.

**Parameters**:

* `fileInfo`: a `FileInfo` object representing a file on the server.
* `success`: To be called on success.
* `error`: To be called on error.

---

```javascript
function onUploadConflictingFile(file, conflictingFileInfo, deleteFromServer, skip) { ... }
```

Determines what to do (asynchronously) when uploading a conflicting file.

* Calls `deleteFromServer()` if the file should be deleted from the server.
* Calls `skip()` if the file should not be uploaded at all.

A file conflicts if it has the same name as an existing file but a different size and/or modification date. While there is no technical reason to prevent uploading `file` alongside `conflictingFileInfo` such that they're both on the server, that almost certainly isn't what the user wants.

 You may implement this as a prompt, for instance, or you can just code something simple like `deleteFromServer()`.

**Parameters**:

* `deleteFromServer`: To be called to indicate the user wants to delete this file from the server.
* `skip`: To be called to indicate the user wants to leave the file alone on the server and not upload the selected file.

---

```javascript
function onStateChanged(state, massUpload) { ... }
```

Does something when the state changes.

In practical terms, callbacks should listen and:

* Display global progress.
* Display error messages (both global and alongside `File` and `FileInfo` representations).
* Prompt the user to resolve errors.
* Submit the form when upload is complete.

**Parameters**:

* `state`, a `State`.
* `massUpload`, a `MassUpload`.

Talking with a server
---------------------

Let's portray an example web service in which the user owns a bunch of folders. For each folder, the user owns some files.

Let's give each file a [GUID](http://en.wikipedia.org/wiki/Globally_unique_identifier) based on its filename, size and lastModifiedDate.

Let's also assume we want to be able to resume uploads. We can't do that with multipart/form-data; instead, we'll upload raw binary blobs.

Our server API might look something like this:

| Method | URL | Parameters | Description |
| ------ | --- | ---------- | ----------- |
| `GET` | `/folders` | | Lists folders |
| `POST` | `/folders` | `name`, `permalink` | Creates a folder |
| `DELETE` | `/folders/:permalink` | | Deletes a folder |
| `PUT` | `/folders/:permalink` | `name` | Renames a folder |
| `GET` | `/folders/:permalink/files` | | Lists a folder's contents |
| `DELETE` | `/folders/:permalink/files` | | Deletes all files from the folder
| `PUT` | `/folders/:permalink/files/:guid` | `name`, `size`, `lastModifiedDate` | Creates an empty file with the given GUID
| `HEAD` | `/folders/:permalink/files/:guid` | | Describes how much of the file is uploaded, using a [`Content-Range`](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.16) header.
| `PATCH` | `/folders/:permalink/files/:guid` | (raw bytes) | Uploads the file's raw bytes using the passed `Content-Range` header. Fails if the `Content-Range` would create a gap in the file or go past the end of the file; succeeds once the file is completely uploaded.
| `DELETE` | `/folders/:permalink/files/:guid` | | Deletes the file from the server

Then our client-side API methods should do something like this:

| Function | Behavior |
| -------- | -------- |
| `doListFiles(progress, success, error)` | Mirrors `GET /folders/:permalink/files` |
| `doUploadFile(file, progress, success, error)` | Determines `guid`; calls `HEAD /folders/:permalink/files/:guid`, optionally calls `PUT /folders/:permalink/files/:guid` if the file does not exist; calculates the missing `Content-Range` and calls `file.slice()` to create a [`Blob`](http://www.w3.org/TR/FileAPI/#dfn-Blob) starting at that range; calls `PATCH /folders/:permalink/files/:guid` sending the `Blob`. (In `jQuery.ajax()`, you can send a blob using `processData: false`.) |
| `doDeleteFile(fileInfo, success, error)` | Determines `guid`; calls `DELETE /folders/:permalink/files/:guid`; calls success if the server responds with success or `404`, otherwise calls error. |

Contributing
------------

To build and contribute:

1. Install [NodeJS](http://nodejs.org/)
2. Clone this repository: `git clone https://github.com/overview/js-mass-upload.git`
3. `npm install` in this directory
4. `grunt develop` to start developing.
5. Write tests in `test/coffee`. In the terminal that's running `grunt develop`, you'll see new failures.
6. Once you've created a test failure, edit code in `src/coffee`, until the terminal that's running `grunt develop` comes up green.
7. Run `grunt` to populate the `dist/` directory.
8. commit and create a pull request.

License
-------

Copyright 2013 The Overview Project

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
