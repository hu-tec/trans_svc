// PC 메뉴 서브 보기
//$(document).ready(function(){
    //$('.company_menu').hide();

    //$('.cate').mouseover(function(){
        //$('.company_menu').show();
    //});
    //$('.company_menu').mouseleave(function(){
        //$('.company_menu').hide();
    //});
//});

//$(function() {
    //$( "#submenu_m" ).accordion({
        //collapsible: true,
        //heightStyle: "content"
    //});
//});

// 메뉴 fixed
$(window).scroll(function(){
  var sticky = $('.part_02'),
      scroll = $(window).scrollTop();

  if (scroll >= 100) sticky.addClass('fixed');
  else sticky.removeClass('fixed');
});

// 회사소개 탭 fixed
$(window).scroll(function(){
  var sticky = $('#inner_tab'),
      scroll = $(window).scrollTop();

  if (scroll >= 100) sticky.addClass('fixed');
  else sticky.removeClass('fixed');
});


// body 태그에 모바일일때 .mobile 추가
$jq(document).ready(function(){
    if(tl_isMobile()) $jq('body').addClass('mobile');
    else $jq('body').addClass('pc');
});

// lazy loading
var lazyLoadInstance = null;
$(document).ready(function(){
	lazyLoadInstance = new LazyLoad({
		elements_selector: ".lazy"
		// ... more custom settings?
	});
});
