    $('#user_pass').passtrength({
        minChars: 6,
        passwordToggle: true,
        tooltip: false
    });

    $("#LgoinBTN").on('click',function (event) {
        event.preventDefault();
        
        Email = $("#user_id").val();
        if (Email.length<3 ) {alert("아이디(Email 주소)를 올바르게 입력하여 주시기 바랍니다."); return false;}

        if ( $("#user_pass").val().length<6 ) {alert("패스워드 6자 이상 입력하여 주시기 바랍니다."); return false;}

        var SNDList = {};
        SNDList.Email = Email;
        SNDList.PWD   = $("#user_pass").val();

        /*$.ajax({
            async : false,
            type : 'POST',
            url : 'login_db.do',
            data: SNDList,
            success: function(result) {
                if (result.isOK == 0) {
                    alert("에러가 발생하였습니다.\n" + result.RText);
                }
                else if (result.isOK == -1) {
                    alert(result.RText);
                }
                else {
                    UserType  = result.utype;
                    UserPoint = result.point;
                    UserCheck = "isOn";

                    if ( result.utype == 21 ) $("#my_expert").css('display', '');
                    if ( result.utype == 99 ) $("#my_manage").css('display', '');

                    $("#LILogout").css('display', '');
                    $("#LILogin").css('display', 'none');
                    $("#LIJoin").css('display', 'none');

                    $("#LIPoint").text("Point "+AddComma(result.point));
                    PageLoad($.cookie('CurrentPage'), 1);
                    //$("#doc_trans").trigger("click");
                }
            },
            error: function(XMLHttpRequest, errorMsg, errorThrown) {
                console.log(errorThrown+" : "+errorMsg);
            }
        });*/
        $.post("/processing/login_proc.do", SNDList, function(result) {
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            }
            else if (result.isOK == -1) {
                alert(result.RText);
            }
            else {
                JOpt = "";
                if ( result.utype == 21 ) {
                    JOpt = "?svc=my_expert";
                }
                else if ( result.utype == 99 ) {
                    JOpt = "?svc=my_manage";
                }

                self.location.href = self.location.pathname+JOpt;

                /*UserType  = result.utype;
                UserPoint = result.point;
                UserCheck = "isOn";*/

                /*if ( result.utype == 21 ) $("#my_expert").css('display', '');
                if ( result.utype == 99 ) $("#my_manage").css('display', '');

                $("#LILogout").css('display', '');
                $("#LILogin").css('display', 'none');
                $("#LIJoin").css('display', 'none');

                $("#LIPoint").text("Point "+AddComma(result.point));
                if ( result.utype == 21 ) PageLoad("my_expert", 1);
                else if ( result.utype == 99 ) PageLoad("my_manage", 1); 
                else PageLoad("doc_trans", 1);*/
                //$("#doc_trans").trigger("click");
            }
        }, "json");
    });
