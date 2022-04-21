// ==================================================
// 
// jquery-input-mask-phone-number 1.0.14
//
// Licensed (The MIT License)
// 
// Copyright © Raja Rama Mohan Thavalam <rajaram.tavalam@gmail.com>
//
// Last Updated On: 22/Aug/2020 IST  12:05 AM 
//
// ==================================================

(function ($) {
    $.fn.usPhoneFormat = function (options) {
        var params = $.extend({
            format: 'xxx-xxx-xxxx',
            international: false,

        }, options);

        if (params.format === 'xxx-xxx-xxxx') {
            $(this).bind('paste', function (e) {
                e.preventDefault();
                var inputValue = e.originalEvent && e.originalEvent.clipboardData.getData('Text');
                inputValue = inputValue.replace(/\D/g, '');
                if (!$.isNumeric(inputValue)) {
                    return false;
                } else {
                    if (inputValue.length > 9) {
                        inputValue = String(inputValue.replace(/(\d{3})(\d{3})(\d{4})/, "$1-$2-$3"));
                    } else {
                        inputValue = String(inputValue.replace(/(\d{3})(?=\d)/g, '$1-'));
                    }
                    $(this).val(inputValue);
                    $(this).val('');
                    inputValue = inputValue.substring(0, 12);
                    $(this).val(inputValue);
                }
            });
            $(this).on('keydown touchend', function (e) {
                e = e || window.event;
                var key = e.which || e.keyCode; // keyCode detection
                var ctrl = e.ctrlKey || e.metaKey || key === 17; // ctrl detection
                if (key == 86 && ctrl) { // Ctrl + V Pressed !
                } else if (key == 67 && ctrl) { // Ctrl + C Pressed !
                } else if (key == 88 && ctrl) { // Ctrl + x Pressed !
                } else if (key == 65 && ctrl) { // Ctrl + a Pressed !
                    $(this).trigger("paste");
                } else if (key != 9 && e.which != 8 && e.which != 0 && !(e.keyCode >= 96 && e.keyCode <= 105) && !(e.keyCode >= 48 && e.keyCode <= 57)) {
                    return false;
                }
                
                var chrVal = $(this).val().replace(/\D/g, '');
                var chrLen = chrVal.length;
                var isSeoul = 0;
                if (chrLen>=2 && chrVal.substr(0,2)=="02") isSeoul=1;
                if ( key==8 || key==46 ) { // Delete
                    if ( isSeoul ) {
                        if ( 3<=chrLen && chrLen<=4 )
                            chrVal = String(chrVal.replace(/(\d{2})(\d{1,3})/, "$1-$2"));
                        else if ( 6<=chrLen)
                            chrVal = String(chrVal.replace(/(\d{2})(\d{3})(\d{1,5})/, "$1-$2-$3"));
                        else chrVal = $(this).val();
                    }
                    else {
                        if ( 4<=chrLen && chrLen<=5 )
                            chrVal = String(chrVal.replace(/(\d{3})(\d{1,3})/, "$1-$2"));
                        else if ( 7<=chrLen)
                            chrVal = String(chrVal.replace(/(\d{3})(\d{3})(\d{1,5})/, "$1-$2-$3"));
                        else chrVal = $(this).val();
                    }
                }
                else if ( e.which != 8 && e.which != 0 ) { // Inpurt
                    if ( isSeoul ) {
                        if (chrLen == 2 ) chrVal = chrVal + "-";
                        else if ( 3<=chrLen && chrLen<5 )
                            chrVal = String(chrVal.replace(/(\d{2})(\d{1,3})/, "$1-$2"));
                        else if ( chrLen==5 )
                            chrVal = String(chrVal.replace(/(\d{2})(\d{3})/, "$1-$2-"));
                        else if ( 6<=chrLen && chrLen<=8 )
                            chrVal = String(chrVal.replace(/(\d{2})(\d{3})(\d{1,3})/, "$1-$2-$3"));
                        else if ( 8 < chrLen )
                            chrVal = String(chrVal.replace(/(\d{2})(\d{4})(\d{3,4})/, "$1-$2-$3"));
                    }
                    else {
                        if (chrLen == 3 ) chrVal = chrVal + "-";
                        else if ( 4<=chrLen && chrLen<6 )
                            chrVal = String(chrVal.replace(/(\d{3})(\d{1,3})/, "$1-$2"));
                        else if ( chrLen==6 )
                            chrVal = String(chrVal.replace(/(\d{3})(\d{3})/, "$1-$2-"));
                        else if ( 7<=chrLen && chrLen<=9 )
                            chrVal = String(chrVal.replace(/(\d{3})(\d{3})(\d{1,3})/, "$1-$2-$3"));
                        else if ( 9 < chrLen )
                            chrVal = String(chrVal.replace(/(\d{3})(\d{4})(\d{3,4})/, "$1-$2-$3"));
                    }
                }
                $(this).val(chrVal);
                if ( isSeoul ) $(this).attr('maxlength', '12');
                else $(this).attr('maxlength', '13');
            });
        } 
    }
}(jQuery));

(function ($) {
    $.fn.usBrithdayFormat = function (options) {
        var params = $.extend({
            format: 'xxxx-xx-xx',
            international: false,

        }, options);

        if (params.format === 'xxxx-xx-xx') {
            $(this).bind('paste', function (e) {
                e.preventDefault();
                var inputValue = e.originalEvent && e.originalEvent.clipboardData.getData('Text');
                inputValue = inputValue.replace(/\D/g, '');
                if (!$.isNumeric(inputValue)) {
                    return false;
                } else {
                    if (inputValue.length > 5) {
                        inputValue = String(inputValue.replace(/(\d{4})(\d{2})(\d{2})/, "$1-$2-$3"));
                    } else {
                        inputValue = String(inputValue.replace(/(\d{4})(?=\d)/g, '$1-'));
                    }
                    $(this).val(inputValue);
                    $(this).val('');
                    inputValue = inputValue.substring(0, 10);
                    $(this).val(inputValue);
                }
            });
            $(this).on('keydown touchend', function (e) {
                e = e || window.event;
                var key = e.which || e.keyCode; // keyCode detection
                var ctrl = e.ctrlKey || e.metaKey || key === 17; // ctrl detection
                if (key == 86 && ctrl) { // Ctrl + V Pressed !
                } else if (key == 67 && ctrl) { // Ctrl + C Pressed !
                } else if (key == 88 && ctrl) { // Ctrl + x Pressed !
                } else if (key == 65 && ctrl) { // Ctrl + a Pressed !
                    $(this).trigger("paste");
                } else if (key != 9 && e.which != 8 && e.which != 0 && !(e.keyCode >= 96 && e.keyCode <= 105) && !(e.keyCode >= 48 && e.keyCode <= 57)) {
                    return false;
                }
                var chrVal = $(this).val().replace(/\D/g, '');
                var chrLen = chrVal.length;
                if ( key==8 || key==46 ) { // Delete
                    if ( 5<chrLen && chrLen<=7 )
                        chrVal = String(chrVal.replace(/(\d{4})(\d{1,2})/, "$1-$2"));
                    else if ( 7<chrLen)
                        chrVal = String(chrVal.replace(/(\d{4})(\d{2})(\d{1,2})/, "$1-$2-$3"));
                }
                else if ( e.which != 8 && e.which != 0 ) { // Input
                    if (chrLen == 4 ) chrVal = chrVal + "-";
                    else if ( chrLen == 5 )
                        chrVal = String(chrVal.replace(/(\d{4})(\d{1,2})/, "$1-$2"));
                    else if ( chrLen == 6 )
                        chrVal = String(chrVal.replace(/(\d{4})(\d{1,2})/, "$1-$2-"));
                    else if ( 6<chrLen )
                        chrVal = String(chrVal.replace(/(\d{4})(\d{2})(\d{1,2})/, "$1-$2-$3"));
                }
                $(this).val(chrVal);
            });
        } 
    }
}(jQuery));
