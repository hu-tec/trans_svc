
<?include "sub_user/user_mypage_menu.js"; ?>

    const 개인정보버튼 = document.querySelector(".my-info");
    const 개인정보 = document.querySelector(".my-info-box");
    const 정보수정버튼 = document.querySelector(".modifi-btn")
    const 개인정보수정 = document.querySelector(".modifi-box");
    const 수정확인버튼 = document.querySelector(".modifi-save");
    const 회원탈퇴버튼 = document.querySelector(".withd");
    const 회원탈퇴 = document.querySelector(".withd-box");
    const 알림함버튼 = document.querySelector(".alert-btn");
    const 알림함 = document.querySelector(".alert-box");

    개인정보버튼.addEventListener("click",function(){
        회원탈퇴.style.display = "none";
        개인정보수정.style.display = "none";
        알림함.style.display = "none";
        개인정보.style.display = "block";
    });

    정보수정버튼.addEventListener("click",function(){
        개인정보.style.display = "none";
        개인정보수정.style.display = "block";
    });

    회원탈퇴버튼.addEventListener("click",function(){
        개인정보.style.display = "none";
        개인정보수정.style.display = "none";
        알림함.style.display = "none";
        회원탈퇴.style.display = "block";
    });

    개인정보버튼.addEventListener("click",function(){
        회원탈퇴.style.display = "none";
        개인정보수정.style.display = "none";
        알림함.style.display = "none";
        개인정보.style.display = "block";
    });
    수정확인버튼.addEventListener("click",function(){
        개인정보수정.style.display = "none";
        개인정보.style.display = "block";
    });
    알림함버튼.addEventListener("click",function(){
        개인정보.style.display = "none";
        개인정보수정.style.display = "none";
        회원탈퇴.style.display = "none";
        알림함.style.display = "block";
    });

    $('#NEW_PWD1, #NEW_PWD2').passtrength({
        minChars: 6,
        passwordToggle: true,
        tooltip: true
    });
    $('#Phone').usPhoneFormat();
    $('#Birthday').usBrithdayFormat();
    //////////////////////////////////////////////
    var BirthdayText = "0000-00-00";
    function Get_User_Info() {
        var SNDList = {};
        $.post("/processing/user_proc_private_info.do", SNDList, function(result) {
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            }
            else {
                $("#UserName").text(result.name);
                $("#InfoEmail").text(result.userid);
                $("#InfoPhone").text(result.phone);

                $("#InfoACCName").text(result.account_name);
                $("#InfoACCNumber").text(result.account_number);

                //////////////
                $("#Email").val(result.userid);

                if ( parseInt(result.birthday_yy) > 0 ) {
                    BirthdayText = result.birthday_yy + "-" + result.birthday_mm + "-" + result.birthday_dd;
                    $("#YYMMDD").text(BirthdayText);
                    $("#Birthday").val(BirthdayText);
                }

                $("#Phone").val(result.phone);

                $("#ACC_Name").val(result.account_name);
                $("#ACC_Number").val(result.account_number);
            }
        });
    }

    /********************************************/
    $("#BTN_PWD_Check").on('click',function (e) {
        if ( $("#ChkPWD").val().length < 1 ) {
            alert("확인용 비밀번호를 입력하여 주십시오.");
            $("#UpdateOK_Modal_BTN").trigger("click");
        }
    });

    /********************************************/
    $("#BTN_Update_Info").on('click',function (e) {
        var SNDList = {};
        var isUpdate=0;

        if ( $("#ChkPWD").val().length < 1 ) { alert("확인용 비밀번호를 입력하여 주십시오."); return false; }
        SNDList.ChkPWD = $("#ChkPWD").val();

        if ( BirthdayText != $("#Birthday").val() ) {
            if ( $("#Birthday").val().length<10 ) {alert("생년월일을 입력해 주시기 바랍니다."); return false;}
            SNDList.Birthday = $("#Birthday").val();
            isUpdate = 1;
        }
        if ( $("#InfoPhone").text() != $("#Phone").val() ) {
            if ( $("#Phone").val().length<12 ) {alert("전화번호를 입력해 주시기 바랍니다."); return false;}
            SNDList.Phone   = $("#PWD1").val();
            isUpdate = 1;
        }
        if ( $("#InfoACCName").text() != $("#ACC_Name").val() ) {
            if ( $("#ACC_Name").val().length<3 ) {alert("은행명을 정확히 입력해 주시기 바랍니다."); return false;}
            SNDList.ACC_Name = $("#ACC_Name").val();
            isUpdate = 1;
        }
        if ( $("#InfoACCNumber").text() != $("#ACC_Number").val() ) {
            if ( $("#ACC_Number").val().length<3 ) {alert("은행계좌 번호를 정확히 입력해 주시기 바랍니다."); return false;}
            SNDList.ACC_Number = $("#ACC_Number").val();
            isUpdate = 1;
        }
        if ( $("#NEW_PWD1").val().length>0 ) {
            if ( $("#NEW_PWD1").val().length<6 || $("#NEW_PWD2").val().length<6) {alert("패스워드 6자 이상 입력하여 주시기 바랍니다."); return false;}
            if ( $("#NEW_PWD1").val() != $("#NEW_PWD2").val() ) {alert("확인용 비밀번호가 틀립니다. 다시 입력해 주시기 바랍니다."); return false;}
            SNDList.NEW_PWD = $("#NEW_PWD1").val();
            isUpdate = 1;
        }
        
        if ( isUpdate == 1 ) {
            $.post("/processing/user_proc_info_update.do", SNDList, function(result) {
                if (result.isOK == 0) {
                    alert("에러가 발생하였습니다.\n" + result.RText);
                }
                else if (result.isOK == 1) {
                    alert(result.RText);
                    $("#UpdateOK_Modal_BTN").trigger("click");
                }
                else  {
                    BirthdayText = $("#Birthday").val();
                    $("#YYMMDD").text( BirthdayText );
                    $("#InfoPhone").text( $("#Phone").val() );
                    $("#InfoACCName").text( $("#ACC_Name").val() );
                    $("#InfoACCNumber").text( $("#ACC_Number").val() );
                    $("#UpdateOK_Modal").modal("show");
                }
            });
        }
        else {
            alert("변경할 내용이 없습니다.");
            $("#UpdateOK_Modal_BTN").trigger("click");
        }
    });

    /********************************************/
    $("#BTN_Quit").on('click',function (e) {
        if ( $("#Quit_Ment").val().length < 1 ) {alert(" 탈퇴사유를 입력해 주십시오."); return;}
        if ( $("#ChkPWD2").val().length < 1 ) { alert("확인용 비밀번호를 입력하여 주십시오."); return false; }
        
        var SNDList = {};
        SNDList.ChkPWD = $("#ChkPWD2").val();
        SNDList.Quit_Ment = $("#Quit_Ment").val();
        $.post("/processing/user_proc_quit.do", SNDList, function(result) {
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            }
            else if (result.isOK == 1) {
                alert(result.RText);
            }
            $("#QuitModal").modal("hide");

            if (result.isOK == 2)
                $("#logout").trigger("click");
        });
    });
    /********************************************/
    $("#AlertList").on('click',function (e) {
        //////////////-> mtype 0-전체, 1-User, 21 - 전문가
        var SNDList = {};
        Table = $('#MyAlertList').DataTable( {
            "ajax": {
                "type" : "POST",
                "url" : "/processing/user_proc_alert_list.do",
                "data" : SNDList,
                "dataType": "JSON"
            },
            "autoWidth": false,
            "destroy": true,
            "pageLength": 10,
            "lengthMenu": [10, 20, 50, 100],
            "columns": [
                { "data": "seq" }, // 0 SEQ
                { "data": "sdate" }, // 1
                { "data": "message" }, // 2
            ],
            'columnDefs': [
                {'targets': 0, 'className': 'dt-body-center', 'searchable': false}, // seq
                {'targets': 1, 'className': 'dt-body-center'}, // sdate
                {'targets': 2, 'className': 'dt-body-center', // message
                    'render': function (data, type, full, meta) {
                        SET = "<div>" + full.message + "</div>";
                        return SET;
                    }
                },
            ],
            "initComplete": function(settings, json){
            }
        } );
    });

    Get_User_Info();
