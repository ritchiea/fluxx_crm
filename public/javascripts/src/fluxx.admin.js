jQuery(function($){
  $.extend($.fluxx.stage.decorators, {
    '.to-fullscreen-modal': [
      'click', function(e) {
        $.fluxx.util.itEndsWithMe(e);
        var $elem = $(this);
        $.ajax({
          url: $elem.attr('href'),
          success: function(data) {
            $.modal(data, {
              position: ["15%",],
              overlayId: 'modal-overlay',
              containerId: 'modal-container',
              dataId: $elem.attr('data-container-id') ? $elem.attr('data-container-id') : 'simplemodal-data',
              onOpen: function(dialog) {
                $.my.stage.resizeFluxxStage();
                var lastItem =  $.cookie('fluxx-admin-last-item');
                if (lastItem)
                  lastItem =  $('#fluxx-admin li.entry[href="' + lastItem + '"]');
                if (!lastItem || !lastItem[0] || lastItem.length > 1)
                  lastItem = $('#fluxx-admin li.entry:first');
                lastItem.click();
                dialog.overlay.fadeIn(200, function () {
                  dialog.container.fadeIn(200, function () {
                    dialog.data.fadeIn(200)
                  });
                });
              },
              onClose: function(dialog) {
                dialog.data.fadeOut(200, function () {
                  dialog.container.fadeOut(200, function () {
                    dialog.overlay.fadeOut(200, function () {
                      $.modal.close();
                    });
                  });
                });
              }
            });
          }
        });
      }
    ],
    '.to-admin': [
      'click', function(e) {
        $.fluxx.util.itEndsWithMe(e);
        var $elem = $(this);
        if ($elem.attr('href') != "") {
          $.cookie('fluxx-admin-last-item', $elem.attr('href'));
          $('#admin-buttons').fadeOut();
          $('#fluxx-admin li.entry').removeClass('selected');
          $elem.addClass('selected');
          var $detail = $('#fluxx-admin .fluxx-admin-partial');
          $detail.fluxxCard().closeCardModal();
          var properties = {
            area: $detail,
            url: $elem.attr('href')
          };
           $detail
            .addClass('updating')
            .children()
            .fadeTo(300, 0);
          $elem.fluxxCardLoadContent(properties, function() {
            $detail.removeClass('updating').children().fadeTo(300, 1);
          });
        }
      }
    ],
    'a.insert-liquid-field' : [
      'click', function(e) {
        $.fluxx.util.itEndsWithMe(e);
        alert('foo');
      }
    ]
  });
  $.extend(true, {
      fluxx: {
        utility: {
          insertLiquidField: function ($form) {
            var field = '',
                $attribute = $form.find('#form_element_attribute_name'),
                i = 0;
            while ($attribute.length > 0) {
              field += $attribute.val() + '.';
              $attribute = $form.find('#form_element_config_attribute_name_' + i++);
            }
            field = '{{ model.' + field.slice(0, - 1) + ' }}';
            var $input = $('#fluxx-admin #view_template_template_text');
            var oldVal = $input.val();
            var curPos = $input.getCursorPosition();
            $input.val(oldVal.slice(0, curPos) + field + oldVal.slice(curPos));
            $('#fluxx-admin .close-modal').click();

          }
        }
      }
  });
});

new function($) {
  $.fn.getCursorPosition = function() {
    var pos = 0;
    var el = $(this).get(0);
    // IE Support
    if (document.selection) {
        el.focus();
        var Sel = document.selection.createRange();
        var SelLength = document.selection.createRange().text.length;
        Sel.moveStart('character', -el.value.length);
        pos = Sel.text.length - SelLength;
    }
    // Firefox support
    else if (el.selectionStart || el.selectionStart == '0')
        pos = el.selectionStart;

    return pos;
  }
} (jQuery);
