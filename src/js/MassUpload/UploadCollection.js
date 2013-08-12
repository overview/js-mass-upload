define(['backbone', './upload'], function(Backbone, Upload) {
  return Backbone.Collection.extend({
    model: Upload
  });
});
