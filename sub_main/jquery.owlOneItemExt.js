(function($) {
  $.fn.owlOneItemExt = function(opts) {
    if (!!opts["init_youtube_api"]) {
      if (!window.youtube_api_loaded) {
        var tag = document.createElement("script");
        tag.src = "https://www.youtube.com/iframe_api";
        var firstScriptTag = document.getElementsByTagName("script")[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
        window.youtube_api_loaded = true;
      }

      if (typeof window.YOUTUBE_CALLBACK_LIST == "undefined") {
        window.YOUTUBE_CALLBACK_LIST = [];
      }

      if (typeof window.onYouTubeIframeAPIReady != "function") {
        window.onYouTubeIframeAPIReady = function() {
          for (var i = 0; i < YOUTUBE_CALLBACK_LIST.length; i++) {
            YOUTUBE_CALLBACK_LIST[i]();
          }
        };
      }
    }

    return this.each(function() {
      var options = $.extend({}, $.fn.owlOneItemExt.defaults, opts || {});
      var $el = $(this);
      // 고정
      options.items = 1;
      // 텍스트
      var dot_texts = [];
      // 타이머
      var dot_timers = [];
      var dot_styles = [];
      var $at = null;
      var timer = options.autoplayTimeout;
      var youtube_idxs = [];
      var st = new Date().getTime(); // 시작시간
      $el.children().each(function(index, element) {
        var $li = $(this);
        if (index == 0) timer = $li.data("timer") || options.autoplayTimeout;
        $li.data("idx", index);
        dot_texts.push($li.data("text"));
        dot_styles.push($li.data("style"));
        dot_timers.push($li.data("timer") || options.autoplayTimeout);

        if ($li.data("youtube")) {
          youtube_idxs.push(index);
        }
      });

      var has_youtube = false;
      var yt_players = [];
      $el.data("yt_players", yt_players); // 외부에서 접근 가능하게...
      function onYouTubeIframeAPIReady() {
        $el.find("li iframe").each(function(index, element) {
          var $iframe = $(this);
          var player = new YT.Player(element, {
            events: {
              onReady: function(event) {
                yt_players.push(event.target);
                $iframe.data("yt_player", event.target);
                event.target.setVolume(0); //최초볼륨크기
              }
            }
          });
        });
      }

      options.onInitialized = function(e) {
        //$el.find('.owl-dot').contents().unwrap().wrap( '<div role="button" class="owl-dot"></div>');
        $el.find(".owl-item >").each(function(index, element) {
          //youtube dom 추가작업
          var $li = $(this);
          if ($li.data("youtube")) {
            $li.html(
              '<iframe src="https://www.youtube.com/embed/' +
                $li.data("youtube") +
                "?playlist=" +
                $li.data("youtube") +
                '&rel=0&showinfo=0&autoplay=0&loop=1&vq=hd1080&color=white&enablejsapi=1" data-no="' +
                index +
                '"  allow="autoplay"></iframe>' +
                '<div class="bg" style="position:absolute;z-index:1;width:100%;height:100%;top:0;left:0;opacity:1"></div>' +
                ""
            );
            has_youtube = true;
          }
        });
        if (has_youtube) {
          YOUTUBE_CALLBACK_LIST.push(onYouTubeIframeAPIReady);
        }

        // DOM 추가

        $el.find(".owl-dots .owl-dot").each(function(index, element) {
          var is_youtube = false;

          if (youtube_idxs.indexOf(index) != -1) is_youtube = true;
          if (dot_texts[index] || dot_styles[index]) {
            var html =
              '<span></span><div class="' +
              (is_youtube ? "text yt-text" : "text") +
              '"' + (dot_styles[index] ? ' style="'+dot_styles[index]+'"' : '')+'>' +
              dot_texts[index] +
              "";
            if (is_youtube) {
              html += '<i class="yt-mute xi-volume-mute"></i>';
            }
            html += "</div>";
            $(this).html(html);
          }
        });

        var volume = 0;
        if (has_youtube) {
          $el.find(".yt-mute").click(function(event) {
            event.stopPropagation();
            if (volume == 50) {
              //볼륨크기
              $(this)
                .removeClass("xi-volume-up")
                .addClass("xi-volume-mute");
              volume = 0;
            } else {
              $(this)
                .removeClass("xi-volume-mute")
                .addClass("xi-volume-up");
              volume = 50; //볼륨크기
            }
            //console.log($el.find('.active').html());
            //$el.find('.active iframe').data('yt_player').setVolume(volume);
            for (var i = 0; i < yt_players.length; i++) {
              yt_players[i].setVolume(volume);
            }
          });
        }
        changed();
      };

      if (options.autoplayHoverPause) {
        $el.mouseenter(function() {
          new Date().getTime();
          if ($at) $at.stop(true);
        });
        $el.mouseleave(function() {
          //autoplayHoverPause 후 timer 기본으로 초기화 버그
          //timer = options.autoplayTimeout;

          if ($at) {
            var t = timer - (timer * $at.width()) / $at.parent().width();
            $at.animate(
              {
                width: "100%"
              },
              t,
              "linear"
            );
          }
          if (timer != options.autoplayTimeout) {
            setTimeout(function() {
              $el.trigger("stop.owl.autoplay");
              $el.trigger("play.owl.autoplay", [t]);
            }, 1);
          }
        });
      }

      $el.owlCarousel(options);

      function changed_carousel(t) {
        $el
          .find(".owl-dots .owl-dot span")
          .stop()
          .width(0);

        $at = $el.find(".owl-dots .owl-dot.active span").animate(
          {
            width: "100%"
          },
          t || timer || options.autoplayTimeout,
          "linear"
        );
      }

      function changed() {
        for (var i = 0; i < yt_players.length; i++) {
          yt_players[i].stopVideo();
        }
        pt = new Date().getTime(); //시작시간초기화
        setTimeout(function() {
          var $li = $el.find(".active >");
          var idx = $li.data("idx");

          $el.trigger("stop.owl.autoplay");
          var t = (timer = dot_timers[idx] || options.autoplayTimeout);
          $el.trigger("play.owl.autoplay", [t]);
          changed_carousel(t);
          if ($li.data("youtube")) {
            $li
              .find("iframe")
              .data("yt_player")
              .playVideo();
          }
        }, 1);
      }

      if (options.autoplay) {
        $el.on("changed.owl.carousel", function(event) {
          changed();
        });
      }
    });
  };
 /*
  $.fn.owlOneItemExt.defaults = {
    loop: true, //clone이 생성되어 rewind?
    rewind: false,
    items: 1,
    autoplay: true,
    autoplayTimeout: 5000,
    autoplayHoverPause: false
  }; */
})($jq || jQuery); //$jq 우선
