    $("#MyPageMenu li").removeClass("is-active");
    $("#MyPageMenu #<?if ( isset($_GET['svc']) ) echo $_GET['svc']?>").toggleClass("is-active");
