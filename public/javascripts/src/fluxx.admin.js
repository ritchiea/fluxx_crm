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
              position: ["10%"],
              overlayId: 'modal-overlay',
              containerId: 'modal-container',
              dataId: $elem.attr('data-container-id') ? $elem.attr('data-container-id') : 'simplemodal-data',
              onOpen: function(dialog) {
                var lastItem =  $.cookie('fluxx-admin-last-item');
                if (lastItem)
                  lastItem =  $('#fluxx-admin li.entry[href="' + lastItem + '"]');
                if (!lastItem || !lastItem[0] || lastItem.length > 1)
                  lastItem = $('#fluxx-admin li.entry:first');
                lastItem.click();
                dialog.overlay.fadeIn(200, function () {
                  dialog.container.fadeIn(200, function () {
                    dialog.data.fadeIn(200, function () {
                      $.my.stage.resizeFluxxStage();
                    });
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
          var $buttons = $('#fluxx-admin #admin-buttons');
          if ($elem.hasClass('show-save-buttons'))
            $buttons.show();
          else
            $buttons.hide();
          $elem.fluxxCardLoadContent(properties, function() {
            $detail.removeClass('updating').children().fadeTo(300, 1);
            $.my.stage.resizeFluxxStage();
          });
        }
      }
    ]
  });
  $.extend(true, {
      fluxx: {
        utility: {
          insertLiquidField: function ($elem) {
            var $form = $elem.parents('form:first')
            var field = '',
                $attribute = $form.find('[name="element_name"]'),
                i = 0;
            while ($attribute[0] && $attribute.val()) {
              var $nextAttr = $form.find('[name = "config_element_name_' + i++ + '"]');
              var attr = ($nextAttr[0] && $nextAttr.val() ? $attribute.val().replace(/\_id$/, '') : $attribute.val());
              field += attr + '.';
              $attribute = $nextAttr;
            }
            var object_name = $form.find('input[name=insert_object_name]').val();
            if (field) {
              field = '{{ ' + (object_name || 'model') + '.' + field.slice(0, - 1) + ' }}';
              var $input = $('#fluxx-admin #view_template_template_text');
              var $close = $('#fluxx-admin .close-modal');
              if (!$input[0]) {
                $input = $('iframe', $form.fluxxCard());
                if ($input[0])
                  $input.rteInsertHTML(field);
                $input = $('.wysiwyg', $form.fluxxCard());
                $close = $('.close-modal', $form.fluxxCard());
              }
              var oldVal = $input.val();
              var curPos = $input.getCursorPosition();
              if (field)
                $input.val(oldVal.slice(0, curPos) + field + oldVal.slice(curPos));
              $input.change();
            }
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
