<?include "sub_user/user_mypage_menu.js"; ?>
    $("#MyPoint").text( AddComma(UserPoint) );

    var isMyPage=1;
<? include "sub_cost_inc/purchase_point.js" ?>

    //----------------------------------------------//
    function My_Point_List( MIdx, isSearch ) {
        $("#DIV_MyPointList").css("display" , "");
        $("#DIV_MyWithdrawalList").css("display" , "none");
        $("#DIV_MyPurchaseList").css("display" , "none");

        var SNDList = {};
        SNDList.MIdx = MIdx;
        SNDList.isSearch = isSearch;

        if ( isSearch == 1 ) {
            if ( $('#StartDate').val().length > 0 ) SNDList.StartDate = $('#StartDate').val();
            if ( $('#EndDate').val().length > 0 ) SNDList.EndDate = $('#EndDate').val();
        }

        $('#MyPointList').DataTable( {
            "ajax": {
                "type" : "POST",
                "url" : "/processing/user_proc_point_list.do",
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
                { "data": "type" }, // 2
                { "data": "amount" }, // 3
                { "data": "point" }, // 4
                null, // 5
            ],
            'columnDefs': [
                {'targets': 0, 'className': 'dt-body-center', 'searchable': false}, // seq
                {'targets': 1, 'className': 'dt-body-center'}, // sdate
                {'targets': 2, 'className': 'dt-body-center' }, // type
                {'targets': 3, 'className': 'dt-body-center', // amount
                    'render': function (data, type, full, meta) {
                        SET = "<span class='";
                        if ( parseInt(full.amount) > 0 ) SET += "has-text-link";
                        else                             SET += "has-text-danger";
                        SET += "'>";
                        SET += AddComma(full.amount);
                        SET += " <i aria-hidden='true' class='fab fa-product-hunt'></i></span>";
                        return SET;
                    }
                },
                {'targets': 4, 'className': 'dt-body-center',  // point
                    'render': function (data, type, full, meta) {
                        return AddComma(full.point);
                    }
                },
                {'targets': 5, 'className': 'dt-body-center',
                    'render': function (data, type, full, meta) {
                        return "";
                    }
                },
            ],
            "initComplete": function(settings, json){
                $('#MyPointList').DataTable().column(5).visible(false);
                if ( MIdx == 1 || MIdx == 2 )
                    $('#MyPointList').DataTable().column(4).visible(false);
            }
        } );
    }
    //----------------------------------------------//
    function My_Withdrawal_List( MIdx, isSearch ) {
        $("#DIV_MyPointList").css("display" , "none");
        $("#DIV_MyWithdrawalList").css("display" , "");
        $("#DIV_MyPurchaseList").css("display" , "none");


        var SNDList = {};
        SNDList.MIdx = MIdx;
        SNDList.isSearch = isSearch;

        if ( isSearch == 1 ) {
            if ( $('#StartDate').val().length > 0 ) SNDList.StartDate = $('#StartDate').val();
            if ( $('#EndDate').val().length > 0 ) SNDList.EndDate = $('#EndDate').val();
        }

        $('#MyWithdrawalList').DataTable( {
            "ajax": {
                "type" : "POST",
                "url" : "/processing/user_proc_pointout_list.do",
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
                { "data": "amount" }, // 2
                { "data": "status" }, // 3
            ],
            'columnDefs': [
                {'targets': 0, 'className': 'dt-body-center', 'searchable': false}, // seq
                {'targets': 1, 'className': 'dt-body-center'}, // sdate
                {'targets': 2, 'className': 'dt-body-right', // amount
                    'render': function (data, type, full, meta) {
                        return AddComma(full.amount);
                    }
                },
                {'targets': 3, 'className': 'dt-body-center', // status
                    'render': function (data, type, full, meta) {
                        SET = "";
                        if ( full.status == 0 ) SET = "출금 요청";
                        else if ( full.status == 1 ) SET = "출금 취소";
                        else if ( full.status == 2 ) SET = "출금 완료";
                        return SET;
                    }
                },
            ],
            "initComplete": function(settings, json){
            }
        } );
    }
    //----------------------------------------------//
    function My_Purchase_List( MIdx, isSearch ) {
        $("#DIV_MyPointList").css("display" , "none");
        $("#DIV_MyWithdrawalList").css("display" , "none");
        $("#DIV_MyPurchaseList").css("display" , "");

        var SNDList = {};
        SNDList.MIdx = MIdx;
        SNDList.isSearch = isSearch;

        if ( isSearch == 1 ) {
            if ( $('#StartDate').val().length > 0 ) SNDList.StartDate = $('#StartDate').val();
            if ( $('#EndDate').val().length > 0 ) SNDList.EndDate = $('#EndDate').val();
        }

        $('#MyPurchaseList').DataTable( {
            "ajax": {
                "type" : "POST",
                "url" : "/processing/user_proc_purchase_list.do",
                "data" : SNDList,
                "dataType": "JSON"
            },
            "autoWidth": false,
            "destroy": true,
            "pageLength": 10,
            "lengthMenu": [10, 20, 50, 100],
            "columns": [
                { "data": "seq" }, // 0 SEQ
                { "data": "svctype" }, // 1
                { "data": "sdate" }, // 2
                { "data": "trans_type" }, // 3
                { "data": "qa_premium" }, // 4
                { "data": "expert_category" }, // 5
                { "data": "layout" }, // 6
                { "data": "urgent" }, // 7
                { "data": "cost" }, // 8
                { "data": "pg_case" }, // 9
            ],
            'columnDefs': [
                {'targets': 0, 'className': 'dt-body-center', 'searchable': false}, // seq
                {'targets': 1, 'className': 'dt-body-center', 'visible': false}, // stype
                {'targets': 2, 'className': 'dt-body-center'}, // sdate
                {'targets': 3, 'className': 'dt-body-center', // trans_type
                    'render': function (data, type, full, meta) {
                        return ServiceType(full.svctype, full.trans_type);
                    }
                },
                {'targets': 4, 'className': 'dt-body-center', // qa_premium
                    'render': function (data, type, full, meta) {
                        return ServiceOption(full.urgent, full.qa_premium, full.expert_category, full.layout);
                    }
                },
                {'targets': 5, 'className': 'dt-body-center', 'visible': false}, // expert_category
                {'targets': 6, 'className': 'dt-body-center', 'visible': false}, // layout
                {'targets': 7, 'className': 'dt-body-center', 'visible': false}, // urgent
                {'targets': 8, 'className': 'dt-body-right', // cost
                    'render': function (data, type, full, meta) {
                        return AddComma(full.cost);
                    }
                },
                {'targets': 9, 'className': 'dt-body-center',  // pg_case
                    'render': function (data, type, full, meta) {
                        SET = "포인트";
                        if ( full.pg_case == 2 ) SET = "카드";
                        else if ( full.pg_case == 3 ) SET = "실시간 계좌이체";
                        else if ( full.pg_case == 4 ) SET = "휴대폰결제";
                        else if ( full.pg_case == 5 ) SET = "무통장 입금";
                        return SET;
                    }
                },
            ],
            "initComplete": function(settings, json){
            }
        } );
    }
    
    //----------------------------------------------//
    var PointQMenu_Index=0;    
    $("#PointQMenu").on('click', 'li', function (e) {
        e.preventDefault();
        $("#PointQMenu li").removeClass("is-active");
        $(this).toggleClass("is-active");
        PointQMenu_Index = $(this).index();
        if ( PointQMenu_Index < 3 )
            My_Point_List( PointQMenu_Index, 0 );
        else if ( PointQMenu_Index == 3 ) 
            My_Withdrawal_List( PointQMenu_Index, 0 );
        else if ( PointQMenu_Index == 4 ) 
            My_Purchase_List( PointQMenu_Index, 0 );

    });
    $("#PointSearch").on('click', function (e) {
        e.preventDefault();
        if ( PointQMenu_Index < 3 )
            My_Point_List( PointQMenu_Index, 1 );
        else if ( PointQMenu_Index == 3 ) 
            My_Withdrawal_List( PointQMenu_Index, 1 );
        else if ( PointQMenu_Index == 4 ) 
            My_Purchase_List( PointQMenu_Index, 1 );
    });

    //----------------------------------------------//
    $("#BTN_PointOut_GO").on('click', function (e) {
        e.preventDefault();
        // 포인트 차감, 화면 전체 포인트 수정
        var SNDList = {};
        SNDList.PointOut = $("#PointOut").val();
        $.post("/processing/user_proc_pointout_submit.do", SNDList, function(result) {
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            } 
            else if (result.isOK == 2) {
                alert(result.RText);
            }
            else if (result.isOK == 1) {
                $("#LIPoint").text("Point "+AddComma(result.point));
                $("#MyPoint").text( AddComma(result.point) );
                UserPoint = result.point;

                $("#Dis_OutPoint").text( AddComma( $("#PointOut").val() ) );
                $("#Dis_OutPoint_Msg").css("display" , "");
                $("#BTN_PointOut_Open").attr('disabled', true);
                $("#BTN_PointOut_Close").trigger("click");
            } 
        });
    });

    $("#BTN_PointOut_Cancel").on('click', function (e) {
        e.preventDefault();
        // 출금 포인트 복원, 화면 전체 포인트 수정
        var SNDList = {};
        $.post("/processing/user_proc_pointout_cancel.do", SNDList, function(result) {
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            } 
            else if (result.isOK == 1) {
                $("#LIPoint").text("Point "+AddComma(result.point));
                $("#MyPoint").text( AddComma(result.point) );
                UserPoint = result.point;

                $("#Dis_OutPoint").text( "0" );
                $("#Dis_OutPoint_Msg").css("display" , "none");
                $("#BTN_PointOut_Open").attr('disabled', false);
            } 
        });
    });

    //----------------------------------------------//
    function get_Point_Out_Info() {
        var SNDList = {};
        $.post("/processing/user_proc_pointout_info.do", SNDList, function(result) {
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            }
            else if (result.isOK == 2) {}
            else if (result.isOK == 1) {
                $("#Dis_OutPoint").text( AddComma( result.amount ) );
                $("#Dis_OutPoint_Msg").css("display" , "");
                $("#BTN_PointOut_Open").attr('disabled', true);
            } 
            My_Point_List( 0, 0 );
        });
    }

    get_Point_Out_Info();
