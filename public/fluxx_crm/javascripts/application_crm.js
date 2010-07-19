jQuery(function($){
  $.extend($.fluxx.stage.decorators, {
    'input[name=grape[id]]': [
      'change', function(e) {
        var $id   = $(this),
            $drop = $id.siblings('.grape-id-drop');
        $.fluxx.log("changing picker...");
        $drop.text('Picked: ' + $id.val());
      }
    ]
  });
});

