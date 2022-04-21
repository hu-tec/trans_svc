(function($) {
  $.fn.owlTimer = function(opts) {

    return this.each(function() {
      var options = $.extend({}, $.fn.owlTimer.defaults, opts || {});
      var $el = $(this);
      // 타이머
      var $at = null;
      var timer = options.autoplayTimeout;

      options.onInitialized = function(e) {
        if (options.autoplay) {
          changed_carousel();
        }
      };

      if (options.autoplayHoverPause) {
        $el.mouseenter(function() {
          if ($at) $at.stop(true);
        });
        $el.mouseleave(function() {
          timer = options.autoplayTimeout;
          if ($at) {
            var t = (timer - timer * $at.width() / $at.parent().width());
            $at.animate({ width: '100%' }, t, 'linear');
          }
        });
      }

      $el.owlCarousel(options);

      function changed_carousel() {
        $el.find('.owl-dots .owl-dot span').stop().width(0);
        $at = $el.find('.owl-dots .owl-dot.active span').animate({ width: '100%' }, options.autoplayTimeout, 'linear');
      }
      if (options.autoplay) {
        $el.on('changed.owl.carousel', function(event) {
          changed_carousel();
        });
      }
    });
  };

  $.fn.owlTimer.defaults = {
  }
})($jq || jQuery);
