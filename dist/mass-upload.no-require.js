(function () {
/**
 * almond 0.2.5 Copyright (c) 2011-2012, The Dojo Foundation All Rights Reserved.
 * Available via the MIT or new BSD license.
 * see: http://github.com/jrburke/almond for details
 */
//Going sloppy to avoid 'use strict' string cost, but strict practices should
//be followed.
/*jslint sloppy: true */
/*global setTimeout: false */

var requirejs, require, define;
(function (undef) {
    var main, req, makeMap, handlers,
        defined = {},
        waiting = {},
        config = {},
        defining = {},
        hasOwn = Object.prototype.hasOwnProperty,
        aps = [].slice;

    function hasProp(obj, prop) {
        return hasOwn.call(obj, prop);
    }

    /**
     * Given a relative module name, like ./something, normalize it to
     * a real name that can be mapped to a path.
     * @param {String} name the relative name
     * @param {String} baseName a real name that the name arg is relative
     * to.
     * @returns {String} normalized name
     */
    function normalize(name, baseName) {
        var nameParts, nameSegment, mapValue, foundMap,
            foundI, foundStarMap, starI, i, j, part,
            baseParts = baseName && baseName.split("/"),
            map = config.map,
            starMap = (map && map['*']) || {};

        //Adjust any relative paths.
        if (name && name.charAt(0) === ".") {
            //If have a base name, try to normalize against it,
            //otherwise, assume it is a top-level require that will
            //be relative to baseUrl in the end.
            if (baseName) {
                //Convert baseName to array, and lop off the last part,
                //so that . matches that "directory" and not name of the baseName's
                //module. For instance, baseName of "one/two/three", maps to
                //"one/two/three.js", but we want the directory, "one/two" for
                //this normalization.
                baseParts = baseParts.slice(0, baseParts.length - 1);

                name = baseParts.concat(name.split("/"));

                //start trimDots
                for (i = 0; i < name.length; i += 1) {
                    part = name[i];
                    if (part === ".") {
                        name.splice(i, 1);
                        i -= 1;
                    } else if (part === "..") {
                        if (i === 1 && (name[2] === '..' || name[0] === '..')) {
                            //End of the line. Keep at least one non-dot
                            //path segment at the front so it can be mapped
                            //correctly to disk. Otherwise, there is likely
                            //no path mapping for a path starting with '..'.
                            //This can still fail, but catches the most reasonable
                            //uses of ..
                            break;
                        } else if (i > 0) {
                            name.splice(i - 1, 2);
                            i -= 2;
                        }
                    }
                }
                //end trimDots

                name = name.join("/");
            } else if (name.indexOf('./') === 0) {
                // No baseName, so this is ID is resolved relative
                // to baseUrl, pull off the leading dot.
                name = name.substring(2);
            }
        }

        //Apply map config if available.
        if ((baseParts || starMap) && map) {
            nameParts = name.split('/');

            for (i = nameParts.length; i > 0; i -= 1) {
                nameSegment = nameParts.slice(0, i).join("/");

                if (baseParts) {
                    //Find the longest baseName segment match in the config.
                    //So, do joins on the biggest to smallest lengths of baseParts.
                    for (j = baseParts.length; j > 0; j -= 1) {
                        mapValue = map[baseParts.slice(0, j).join('/')];

                        //baseName segment has  config, find if it has one for
                        //this name.
                        if (mapValue) {
                            mapValue = mapValue[nameSegment];
                            if (mapValue) {
                                //Match, update name to the new value.
                                foundMap = mapValue;
                                foundI = i;
                                break;
                            }
                        }
                    }
                }

                if (foundMap) {
                    break;
                }

                //Check for a star map match, but just hold on to it,
                //if there is a shorter segment match later in a matching
                //config, then favor over this star map.
                if (!foundStarMap && starMap && starMap[nameSegment]) {
                    foundStarMap = starMap[nameSegment];
                    starI = i;
                }
            }

            if (!foundMap && foundStarMap) {
                foundMap = foundStarMap;
                foundI = starI;
            }

            if (foundMap) {
                nameParts.splice(0, foundI, foundMap);
                name = nameParts.join('/');
            }
        }

        return name;
    }

    function makeRequire(relName, forceSync) {
        return function () {
            //A version of a require function that passes a moduleName
            //value for items that may need to
            //look up paths relative to the moduleName
            return req.apply(undef, aps.call(arguments, 0).concat([relName, forceSync]));
        };
    }

    function makeNormalize(relName) {
        return function (name) {
            return normalize(name, relName);
        };
    }

    function makeLoad(depName) {
        return function (value) {
            defined[depName] = value;
        };
    }

    function callDep(name) {
        if (hasProp(waiting, name)) {
            var args = waiting[name];
            delete waiting[name];
            defining[name] = true;
            main.apply(undef, args);
        }

        if (!hasProp(defined, name) && !hasProp(defining, name)) {
            throw new Error('No ' + name);
        }
        return defined[name];
    }

    //Turns a plugin!resource to [plugin, resource]
    //with the plugin being undefined if the name
    //did not have a plugin prefix.
    function splitPrefix(name) {
        var prefix,
            index = name ? name.indexOf('!') : -1;
        if (index > -1) {
            prefix = name.substring(0, index);
            name = name.substring(index + 1, name.length);
        }
        return [prefix, name];
    }

    /**
     * Makes a name map, normalizing the name, and using a plugin
     * for normalization if necessary. Grabs a ref to plugin
     * too, as an optimization.
     */
    makeMap = function (name, relName) {
        var plugin,
            parts = splitPrefix(name),
            prefix = parts[0];

        name = parts[1];

        if (prefix) {
            prefix = normalize(prefix, relName);
            plugin = callDep(prefix);
        }

        //Normalize according
        if (prefix) {
            if (plugin && plugin.normalize) {
                name = plugin.normalize(name, makeNormalize(relName));
            } else {
                name = normalize(name, relName);
            }
        } else {
            name = normalize(name, relName);
            parts = splitPrefix(name);
            prefix = parts[0];
            name = parts[1];
            if (prefix) {
                plugin = callDep(prefix);
            }
        }

        //Using ridiculous property names for space reasons
        return {
            f: prefix ? prefix + '!' + name : name, //fullName
            n: name,
            pr: prefix,
            p: plugin
        };
    };

    function makeConfig(name) {
        return function () {
            return (config && config.config && config.config[name]) || {};
        };
    }

    handlers = {
        require: function (name) {
            return makeRequire(name);
        },
        exports: function (name) {
            var e = defined[name];
            if (typeof e !== 'undefined') {
                return e;
            } else {
                return (defined[name] = {});
            }
        },
        module: function (name) {
            return {
                id: name,
                uri: '',
                exports: defined[name],
                config: makeConfig(name)
            };
        }
    };

    main = function (name, deps, callback, relName) {
        var cjsModule, depName, ret, map, i,
            args = [],
            usingExports;

        //Use name if no relName
        relName = relName || name;

        //Call the callback to define the module, if necessary.
        if (typeof callback === 'function') {

            //Pull out the defined dependencies and pass the ordered
            //values to the callback.
            //Default to [require, exports, module] if no deps
            deps = !deps.length && callback.length ? ['require', 'exports', 'module'] : deps;
            for (i = 0; i < deps.length; i += 1) {
                map = makeMap(deps[i], relName);
                depName = map.f;

                //Fast path CommonJS standard dependencies.
                if (depName === "require") {
                    args[i] = handlers.require(name);
                } else if (depName === "exports") {
                    //CommonJS module spec 1.1
                    args[i] = handlers.exports(name);
                    usingExports = true;
                } else if (depName === "module") {
                    //CommonJS module spec 1.1
                    cjsModule = args[i] = handlers.module(name);
                } else if (hasProp(defined, depName) ||
                           hasProp(waiting, depName) ||
                           hasProp(defining, depName)) {
                    args[i] = callDep(depName);
                } else if (map.p) {
                    map.p.load(map.n, makeRequire(relName, true), makeLoad(depName), {});
                    args[i] = defined[depName];
                } else {
                    throw new Error(name + ' missing ' + depName);
                }
            }

            ret = callback.apply(defined[name], args);

            if (name) {
                //If setting exports via "module" is in play,
                //favor that over return value and exports. After that,
                //favor a non-undefined return value over exports use.
                if (cjsModule && cjsModule.exports !== undef &&
                        cjsModule.exports !== defined[name]) {
                    defined[name] = cjsModule.exports;
                } else if (ret !== undef || !usingExports) {
                    //Use the return value from the function.
                    defined[name] = ret;
                }
            }
        } else if (name) {
            //May just be an object definition for the module. Only
            //worry about defining if have a module name.
            defined[name] = callback;
        }
    };

    requirejs = require = req = function (deps, callback, relName, forceSync, alt) {
        if (typeof deps === "string") {
            if (handlers[deps]) {
                //callback in this case is really relName
                return handlers[deps](callback);
            }
            //Just return the module wanted. In this scenario, the
            //deps arg is the module name, and second arg (if passed)
            //is just the relName.
            //Normalize module name, if it contains . or ..
            return callDep(makeMap(deps, callback).f);
        } else if (!deps.splice) {
            //deps is a config object, not an array.
            config = deps;
            if (callback.splice) {
                //callback is an array, which means it is a dependency list.
                //Adjust args if there are dependencies
                deps = callback;
                callback = relName;
                relName = null;
            } else {
                deps = undef;
            }
        }

        //Support require(['a'])
        callback = callback || function () {};

        //If relName is a function, it is an errback handler,
        //so remove it.
        if (typeof relName === 'function') {
            relName = forceSync;
            forceSync = alt;
        }

        //Simulate async callback;
        if (forceSync) {
            main(undef, deps, callback, relName);
        } else {
            //Using a non-zero value because of concern for what old browsers
            //do, and latest browsers "upgrade" to 4 if lower value is used:
            //http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#dom-windowtimers-settimeout:
            //If want a value immediately, use require('id') instead -- something
            //that works in almond on the global level, but not guaranteed and
            //unlikely to work in other AMD implementations.
            setTimeout(function () {
                main(undef, deps, callback, relName);
            }, 4);
        }

        return req;
    };

    /**
     * Just drops the config on the floor, but returns req in case
     * the config return value is used.
     */
    req.config = function (cfg) {
        config = cfg;
        if (config.deps) {
            req(config.deps, config.callback);
        }
        return req;
    };

    define = function (name, deps, callback) {

        //This module may not have dependencies
        if (!deps.splice) {
            //deps is not an array, so probably means
            //an object literal or factory function for
            //the value. Adjust args.
            callback = deps;
            deps = [];
        }

        if (!hasProp(defined, name) && !hasProp(waiting, name)) {
            waiting[name] = [name, deps, callback];
        }
    };

    define.amd = {
        jQuery: true
    };
}());

define("almond", function(){});

define('MassUpload/FileInfo',[],function() {
  var FileInfo;
  FileInfo = (function() {
    function FileInfo(name, lastModifiedDate, total, loaded) {
      this.name = name;
      this.lastModifiedDate = lastModifiedDate;
      this.total = total;
      this.loaded = loaded;
    }

    return FileInfo;

  })();
  FileInfo.fromJson = function(obj) {
    return new FileInfo(obj.name, new Date(obj.lastModifiedDate), obj.total, obj.loaded);
  };
  FileInfo.fromFile = function(obj) {
    return new FileInfo(obj.name, obj.lastModifiedDate, obj.size, 0);
  };
  return FileInfo;
});

define('MassUpload/Upload',['backbone', './FileInfo'], function(Backbone, FileInfo) {
  return Backbone.Model.extend({
    defaults: {
      file: null,
      fileInfo: null,
      error: null,
      uploading: false,
      deleting: false
    },
    initialize: function(attributes) {
      var fileLike, id, _ref;
      fileLike = (_ref = attributes.file) != null ? _ref : attributes.fileInfo;
      id = fileLike.name;
      return this.set({
        id: id
      });
    },
    updateWithProgress: function(progressEvent) {
      var fileInfo;
      fileInfo = FileInfo.fromFile(this.get('file'));
      fileInfo.loaded = progressEvent.loaded;
      fileInfo.total = progressEvent.total;
      return this.set('fileInfo', fileInfo);
    },
    getProgress: function() {
      var file, fileInfo;
      if (((fileInfo = this.get('fileInfo')) != null) && !this.hasConflict()) {
        return {
          loaded: fileInfo.loaded,
          total: fileInfo.total
        };
      } else if ((file = this.get('file')) != null) {
        return {
          loaded: 0,
          total: file.size
        };
      }
    },
    isFullyUploaded: function() {
      var error, fileInfo;
      fileInfo = this.get('fileInfo');
      error = this.get('error');
      return !this.get('uploading') && !this.get('deleting') && (this.get('error') == null) && (fileInfo != null) && fileInfo.loaded === fileInfo.total;
    },
    hasConflict: function() {
      var file, fileInfo;
      fileInfo = this.get('fileInfo');
      file = this.get('file');
      return (fileInfo != null) && (file != null) && (fileInfo.name !== file.name || fileInfo.lastModifiedDate.getTime() !== file.lastModifiedDate.getTime() || fileInfo.total !== file.size);
    }
  });
});

define('MassUpload/UploadCollection',['backbone', './Upload'], function(Backbone, Upload) {
  return Backbone.Collection.extend({
    model: Upload,
    comparator: 'id',
    addFiles: function(files) {
      var file, uploads;
      uploads = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = files.length; _i < _len; _i++) {
          file = files[_i];
          _results.push(new Upload({
            file: file
          }));
        }
        return _results;
      })();
      return this._addWithMerge(uploads);
    },
    addFileInfos: function(fileInfos) {
      var fileInfo, uploads;
      uploads = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = fileInfos.length; _i < _len; _i++) {
          fileInfo = fileInfos[_i];
          _results.push(new Upload({
            fileInfo: fileInfo
          }));
        }
        return _results;
      })();
      return this._addWithMerge(uploads);
    },
    next: function() {
      var firstDeleting, firstUnfinished, firstUnstarted, firstUploading;
      firstDeleting = null;
      firstUploading = null;
      firstUnfinished = null;
      firstUnstarted = null;
      this.each(function(upload) {
        var file, fileInfo;
        file = upload.get('file');
        fileInfo = upload.get('fileInfo');
        if (upload.get('error') == null) {
          if (upload.get('deleting')) {
            firstDeleting || (firstDeleting = upload);
          }
          if (upload.get('uploading')) {
            firstUploading || (firstUploading = upload);
          }
          if (file && fileInfo && fileInfo.loaded < fileInfo.total) {
            firstUnfinished || (firstUnfinished = upload);
          }
          if (file && !fileInfo) {
            return firstUnstarted || (firstUnstarted = upload);
          }
        }
      });
      return firstDeleting || firstUploading || firstUnfinished || firstUnstarted;
    },
    _addWithMerge: function(uploads) {
      var existingUpload, file, fileInfo, toAdd, upload, _i, _len;
      toAdd = [];
      for (_i = 0, _len = uploads.length; _i < _len; _i++) {
        upload = uploads[_i];
        if ((existingUpload = this.get(upload.id)) != null) {
          file = upload.get('file');
          fileInfo = upload.get('fileInfo');
          if (file != null) {
            existingUpload.set({
              file: file
            });
          }
          if (fileInfo != null) {
            existingUpload.set({
              fileInfo: fileInfo
            });
          }
        } else {
          toAdd.push(upload);
        }
      }
      return this.add(toAdd);
    }
  });
});

define('MassUpload/FileLister',[],function() {
  var FileLister;
  return FileLister = (function() {
    function FileLister(doListFiles, callbacks) {
      this.doListFiles = doListFiles;
      this.callbacks = callbacks;
      this.running = false;
    }

    FileLister.prototype.run = function() {
      var _base,
        _this = this;
      if (this.running) {
        throw 'already running';
      }
      this.running = true;
      if (typeof (_base = this.callbacks).onStart === "function") {
        _base.onStart();
      }
      return this.doListFiles((function(progressEvent) {
        var _base1;
        return typeof (_base1 = _this.callbacks).onProgress === "function" ? _base1.onProgress(progressEvent) : void 0;
      }), (function(fileInfos) {
        return _this._onSuccess(fileInfos);
      }), (function(errorDetail) {
        return _this._onError(errorDetail);
      }));
    };

    FileLister.prototype._onSuccess = function(fileInfos) {
      var _base;
      if (typeof (_base = this.callbacks).onSuccess === "function") {
        _base.onSuccess(fileInfos);
      }
      return this._onStop();
    };

    FileLister.prototype._onError = function(errorDetail) {
      this.callbacks.onError(errorDetail);
      return this._onStop();
    };

    FileLister.prototype._onStop = function() {
      var _base;
      this.running = false;
      return typeof (_base = this.callbacks).onStop === "function" ? _base.onStop() : void 0;
    };

    return FileLister;

  })();
});

define('MassUpload/FileUploader',['./FileInfo'], function(FileInfo) {
  var FileUploader;
  return FileUploader = (function() {
    function FileUploader(doUpload, callbacks) {
      this.doUpload = doUpload;
      this.callbacks = callbacks;
      this._file = null;
      this._abortCallback = null;
      this._aborting = false;
    }

    FileUploader.prototype.run = function(file) {
      var _base,
        _this = this;
      if (this._file != null) {
        throw 'already running';
      }
      this._file = file;
      if (typeof (_base = this.callbacks).onStart === "function") {
        _base.onStart(this._file);
      }
      return this._abortCallback = this.doUpload(file, (function(progressEvent) {
        return _this._onProgress(file, progressEvent);
      }), (function() {
        return _this._onSuccess(file);
      }), (function(errorDetail) {
        return _this._onError(file, errorDetail);
      }));
    };

    FileUploader.prototype.abort = function() {
      if (this._file && !this._aborting) {
        this._aborting = true;
        if (typeof this._abortCallback === 'function') {
          return this._abortCallback();
        }
      }
    };

    FileUploader.prototype._onProgress = function(file, progressEvent) {
      var _base;
      return typeof (_base = this.callbacks).onProgress === "function" ? _base.onProgress(file, progressEvent) : void 0;
    };

    FileUploader.prototype._onSuccess = function(file) {
      var _base;
      if (typeof (_base = this.callbacks).onSuccess === "function") {
        _base.onSuccess(file);
      }
      return this._onStop(file);
    };

    FileUploader.prototype._onError = function(file, errorDetail) {
      var _base;
      if (typeof (_base = this.callbacks).onError === "function") {
        _base.onError(file, errorDetail);
      }
      return this._onStop(file);
    };

    FileUploader.prototype._onStop = function(file) {
      var _base;
      this._file = null;
      this._abortCallback = null;
      this._aborting = false;
      return typeof (_base = this.callbacks).onStop === "function" ? _base.onStop(file) : void 0;
    };

    return FileUploader;

  })();
});

define('MassUpload/FileDeleter',[],function() {
  var FileDeleter;
  return FileDeleter = (function() {
    function FileDeleter(doDeleteFile, callbacks) {
      this.doDeleteFile = doDeleteFile;
      this.callbacks = callbacks != null ? callbacks : {};
      this.running = false;
    }

    FileDeleter.prototype.run = function(fileInfo) {
      var _base,
        _this = this;
      if (this.running) {
        throw 'already running';
      }
      this.running = true;
      if (typeof (_base = this.callbacks).onStart === "function") {
        _base.onStart(fileInfo);
      }
      return this.doDeleteFile(fileInfo, (function() {
        return _this._onSuccess(fileInfo);
      }), (function(errorDetail) {
        return _this._onError(fileInfo, errorDetail);
      }));
    };

    FileDeleter.prototype._onSuccess = function(fileInfo) {
      var _base;
      if (typeof (_base = this.callbacks).onSuccess === "function") {
        _base.onSuccess(fileInfo);
      }
      return this._onStop(fileInfo);
    };

    FileDeleter.prototype._onError = function(fileInfo, errorDetail) {
      var _base;
      if (typeof (_base = this.callbacks).onError === "function") {
        _base.onError(fileInfo, errorDetail);
      }
      return this._onStop(fileInfo);
    };

    FileDeleter.prototype._onStop = function(fileInfo) {
      var _base;
      this.running = false;
      if (typeof (_base = this.callbacks).onStop === "function") {
        _base.onStop(fileInfo);
      }
      return void 0;
    };

    return FileDeleter;

  })();
});

define('MassUpload/State',[],function() {
  var State;
  return State = (function() {
    function State(attrs) {
      var _ref, _ref1, _ref2, _ref3;
      if (attrs == null) {
        attrs = {};
      }
      this.loaded = (_ref = attrs.loaded) != null ? _ref : 0;
      this.total = (_ref1 = attrs.total) != null ? _ref1 : 0;
      this.status = (_ref2 = attrs.status) != null ? _ref2 : 'waiting';
      this.errors = (_ref3 = attrs.errors) != null ? _ref3 : [];
    }

    State.prototype._extend = function(attrs) {
      var _ref, _ref1, _ref2, _ref3;
      return new State({
        loaded: (_ref = attrs.loaded) != null ? _ref : this.loaded,
        total: (_ref1 = attrs.total) != null ? _ref1 : this.total,
        status: (_ref2 = attrs.status) != null ? _ref2 : this.status,
        errors: (_ref3 = attrs.errors) != null ? _ref3 : this.errors
      });
    };

    State.prototype.isComplete = function() {
      return this.total && this.loaded === this.total && this.status === 'waiting' && !this.errors.length && true || false;
    };

    State.prototype.withTotal = function(total) {
      return this._extend({
        total: total
      });
    };

    State.prototype.withLoaded = function(loaded) {
      return this._extend({
        loaded: loaded
      });
    };

    State.prototype.withStatus = function(status) {
      return this._extend({
        status: status
      });
    };

    State.prototype.withAnError = function(error) {
      var newErrors;
      newErrors = this.errors.slice(0);
      newErrors.push(error);
      return this._extend({
        errors: newErrors
      });
    };

    State.prototype.withoutAnError = function(error) {
      var index, newErrors;
      newErrors = this.errors.slice(0);
      index = newErrors.indexOf(error);
      newErrors.splice(index, 1);
      return this._extend({
        errors: newErrors
      });
    };

    return State;

  })();
});

define('MassUpload/UploadProgress',['backbone'], function(Backbone) {
  return Backbone.Model.extend({
    defaults: {
      loaded: 0,
      total: 0
    },
    initialize: function() {
      var add, adjust, callback, change, cidToLastKnownProgress, collection, eventName, events, remove, reset,
        _this = this;
      collection = this.get('collection');
      if (collection == null) {
        throw 'Must initialize UploadProgress with `collection`, an UploadCollection';
      }
      adjust = function(dLoaded, dTotal) {
        _this.set({
          loaded: _this.get('loaded') + dLoaded,
          total: _this.get('total') + dTotal
        });
        return void 0;
      };
      cidToLastKnownProgress = {};
      add = function(model) {
        var progress;
        progress = model.getProgress();
        adjust(progress.loaded, progress.total);
        return cidToLastKnownProgress[model.cid] = progress;
      };
      remove = function(model) {
        var progress;
        progress = cidToLastKnownProgress[model.cid];
        adjust(-progress.loaded, -progress.total);
        return delete cidToLastKnownProgress[model.cid];
      };
      change = function(model) {
        var newProgress, oldProgress;
        oldProgress = cidToLastKnownProgress[model.cid];
        if (oldProgress != null) {
          newProgress = model.getProgress();
          adjust(newProgress.loaded - oldProgress.loaded, newProgress.total - oldProgress.total);
          return cidToLastKnownProgress[model.cid] = newProgress;
        }
      };
      reset = function() {
        var progress;
        cidToLastKnownProgress = {};
        progress = {
          loaded: 0,
          total: 0
        };
        _this.get('collection').each(function(model) {
          var modelProgress;
          modelProgress = model.getProgress();
          cidToLastKnownProgress[model.cid] = modelProgress;
          progress.loaded += modelProgress.loaded;
          return progress.total += modelProgress.total;
        });
        return _this.set(progress);
      };
      events = {
        add: add,
        remove: remove,
        change: change,
        reset: reset
      };
      for (eventName in events) {
        callback = events[eventName];
        collection.on(eventName, callback);
      }
      reset();
      return void 0;
    }
  });
});

define('MassUpload',['backbone', 'MassUpload/UploadCollection', 'MassUpload/FileLister', 'MassUpload/FileUploader', 'MassUpload/FileDeleter', 'MassUpload/State', 'MassUpload/UploadProgress'], function(Backbone, UploadCollection, FileLister, FileUploader, FileDeleter, State, UploadProgress) {
  return Backbone.Model.extend({
    defaults: function() {
      return {
        status: 'waiting',
        listFilesProgress: null,
        listFilesError: null,
        uploadProgress: null,
        uploadErrors: []
      };
    },
    constructor: function(options) {
      this._removedUploads = [];
      return Backbone.Model.call(this, {}, options);
    },
    initialize: function(attributes, options) {
      var resetUploadProgress, uploadProgress, _ref, _ref1, _ref2, _ref3,
        _this = this;
      this.uploads = (_ref = options != null ? options.uploads : void 0) != null ? _ref : new UploadCollection();
      this.lister = (_ref1 = options != null ? options.lister : void 0) != null ? _ref1 : new FileLister(options.doListFiles);
      this.lister.callbacks = {
        onStart: function() {
          return _this._onListerStart();
        },
        onProgress: function(progressEvent) {
          return _this._onListerProgress(progressEvent);
        },
        onSuccess: function(fileInfos) {
          return _this._onListerSuccess(fileInfos);
        },
        onError: function(errorDetail) {
          return _this._onListerError(errorDetail);
        },
        onStop: function() {
          return _this._onListerStop();
        }
      };
      this.uploader = (_ref2 = options != null ? options.uploader : void 0) != null ? _ref2 : new FileUploader(options.doUploadFile);
      this.uploader.callbacks = {
        onStart: function(file) {
          return _this._onUploaderStart(file);
        },
        onStop: function(file) {
          return _this._onUploaderStop(file);
        },
        onSuccess: function(file) {
          return _this._onUploaderSuccess(file);
        },
        onError: function(file, errorDetail) {
          return _this._onUploaderError(file, errorDetail);
        },
        onProgress: function(file, progressEvent) {
          return _this._onUploaderProgress(file, progressEvent);
        }
      };
      this.deleter = (_ref3 = options != null ? options.deleter : void 0) != null ? _ref3 : new FileDeleter(options.doDeleteFile);
      this.deleter.callbacks = {
        onStart: function(fileInfo) {
          return _this._onDeleterStart(fileInfo);
        },
        onSuccess: function(fileInfo) {
          return _this._onDeleterSuccess(fileInfo);
        },
        onError: function(fileInfo, errorDetail) {
          return _this._onDeleterError(fileInfo, errorDetail);
        },
        onStop: function(fileInfo) {
          return _this._onDeleterStop(fileInfo);
        }
      };
      this.uploads.on('add change:file', function(upload) {
        return _this._onUploadAdded(upload);
      });
      this.uploads.on('change:deleting', function(upload) {
        return _this._onUploadDeleted(upload);
      });
      this.uploads.on('remove', function(upload) {
        return _this._onUploadRemoved(upload);
      });
      uploadProgress = new UploadProgress({
        collection: this.uploads
      });
      resetUploadProgress = function() {
        return _this.set({
          uploadProgress: uploadProgress.pick('loaded', 'total')
        });
      };
      uploadProgress.on('change', resetUploadProgress);
      return resetUploadProgress();
    },
    fetchFileInfosFromServer: function() {
      return this.lister.run();
    },
    retryListFiles: function() {
      return this.fetchFileInfosFromServer();
    },
    addFiles: function(files) {
      return this.uploads.addFiles(files);
    },
    removeUpload: function(upload) {
      return upload.set('deleting', true);
    },
    _onListerStart: function() {
      this.set('status', 'listing-files');
      return this.set('listFilesError', null);
    },
    _onListerProgress: function(progressEvent) {
      return this.set('listFilesProgress', progressEvent);
    },
    _onListerSuccess: function(fileInfos) {
      this.uploads.addFileInfos(fileInfos);
      return this._tick();
    },
    _onListerError: function(errorDetail) {
      this.set('listFilesError', errorDetail);
      return this.set('status', 'listing-files-error');
    },
    _onListerStop: function() {},
    _onUploadAdded: function(upload) {
      var status;
      status = this.get('status');
      if (status === 'uploading' || status === 'uploading-error') {
        return this.uploader.abort();
      } else {
        return this._tick();
      }
    },
    _onUploadRemoved: function(upload) {},
    _onUploadDeleted: function(upload) {
      var status;
      this._removedUploads.push(upload);
      status = this.get('status');
      if (status === 'uploading' || status === 'uploading-error') {
        return this.uploader.abort();
      } else {
        return this._tick();
      }
    },
    _onUploaderStart: function(file) {
      var upload;
      this.set('status', 'uploading');
      upload = this.uploads.get(file.name);
      return upload.set({
        uploading: true,
        error: null
      });
    },
    _onUploaderStop: function(file) {
      var upload;
      upload = this.uploads.get(file.name);
      upload.set('uploading', false);
      return this._tick();
    },
    _onUploaderProgress: function(file, progressEvent) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.updateWithProgress(progressEvent);
    },
    _onUploaderError: function(file, errorDetail) {
      var upload;
      upload = this.uploads.get(file.name);
      return upload.set('error', errorDetail);
    },
    _onUploaderSuccess: function(file) {},
    _onDeleterStart: function(fileInfo) {
      return this.set('status', 'uploading');
    },
    _onDeleterSuccess: function(fileInfo) {
      var upload;
      upload = this.uploads.get(fileInfo.name);
      return this.uploads.remove(upload);
    },
    _onDeleterError: function(fileInfo, errorDetail) {
      var upload;
      upload = this.uploads.get(fileInfo.name);
      return upload.set('error', errorDetail);
    },
    _onDeleterStop: function(fileInfo) {
      return this._tick();
    },
    _tick: function() {
      var upload;
      upload = this.uploads.next();
      if (upload != null) {
        if (upload.get('deleting')) {
          return this.deleter.run(upload.get('fileInfo'));
        } else {
          return this.uploader.run(upload.get('file'));
        }
      } else {
        return this.set('status', 'waiting');
      }
    }
  });
});

require(['./MassUpload'], function(MassUpload) {
  return window.MassUpload = MassUpload;
});

define("index", function(){});
}());