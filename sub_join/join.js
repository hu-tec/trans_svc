    function EmailCheck( email ) {
        var re = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i;
        return re.test(email);
    }

    $('#PWD1, #PWD2').passtrength({
        minChars: 6,
        passwordToggle: true,
        tooltip: true
    });
    $('#Phone').usPhoneFormat();

    $("#check_all").change(function(){
        if( $("#check_all").is(":checked") ){
            $("input:checkbox").prop("checked", true);
        }else{
            $("input:checkbox").prop("checked", false);
        }
    });
    $("#check1, #check2").change(function(){
        if( !$("#check1").is(":checked") || !$("#check2").is(":checked") ){
            $("#check_all").prop("checked", false);
        }
        else $("#check_all").prop("checked", true);
    });

    /********************************************/
    $("#UserSubmit").on('click',function (event) {
        if( !$("#check1").is(":checked") || !$("#check2").is(":checked") ) {alert("[이용약관] 및 [개인정보 수집·이용]에 동의하셔야 회원 가입이 가능합니다."); return false;}
        
        Email = $("#Email").val();
        if (Email.length<3 || !EmailCheck(Email)) {alert("아이디(Email 주소)를 올바르게 입력하여 주시기 바랍니다."); return false;}

        if ( $("#PWD1").val().length<6 || $("#PWD2").val().length<6) {alert("패스워드 6자 이상 입력하여 주시기 바랍니다."); return false;}
        if ( $("#PWD1").val() != $("#PWD2").val() ) {alert("확인용 비밀번호가 틀립니다. 다시 입력해 주시기 바랍니다."); return false;}

        if ( $("#UName").val().length<2 ) {alert("사용자명을 입력해 주시기 바랍니다."); return false;}

        if ( $("#Phone").val().length<12 ) {alert("전화번호를 입력해 주시기 바랍니다."); return false;}

        var SNDList = {};
        SNDList.Email = Email;
        SNDList.PWD   = $("#PWD1").val();
        SNDList.UName = $("#UName").val();
        SNDList.Phone = $("#Phone").val();
        SNDList.Type  = 1;
        $.post("/processing/join_proc.do", SNDList, function(result) {
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            }
            else if (result.isOK == -1) {
                alert(result.RText);
            }
            else $("#login").trigger("click");
        });
    });