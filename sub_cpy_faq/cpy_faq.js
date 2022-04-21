    $('.btn').on('click', function (e) {
        $('.faq-con').removeClass("active");
        $('.accordion-button').addClass("collapsed");
        $('.accordion-collapse').removeClass("show");
        
        SelectedIdx = parseInt( $(this).attr("for").substr(8,1) ) - 1;
        $('.faq-con').eq(SelectedIdx).addClass("active");
    });

    $('.accordion-button').on('click', function (e) {
        $('.accordion-button').addClass("collapsed");
        $('.accordion-collapse').removeClass("show");
    });
