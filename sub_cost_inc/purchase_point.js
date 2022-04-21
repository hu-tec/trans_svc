    /********************** Point Purchase *************************************/
    var PointChargeAmount=0;
    $("#BTN_Recharge_Open, #BTN_Recharge_Cancel").on('click',function (event) {
        if ( isMyPage == 0 ) { // Only Quoation
            // if (this.id == "BTN_Recharge_Open") {
            //     H = parseInt( $("#PurchaseSection").css("height")) + 70;
            //     $("#PurchaseSection").css("min-height", H+"px");
            // }
            // else 
            //     $("#PurchaseSection").css("min-height", "10px");

            // var modalDialog = $(".modal-dialog");
            // modalDialog.css("margin-top", Math.max(0, ($(window).height() - modalDialog.height()) / 2));
        }
    });
    /*******************************/
    $("#PointBtnGrp button").on('click',function (event) {
        PointChargeAmount = parseInt( $(this).text().replace(/\s/g, '').replace(/,/g, '') );
        
        if ( PointChargeAmount == 0 ) return;
        //alert( "["+Val+"]" );

        $("#PointBtnGrp button").removeClass("is-success");
        $(this).toggleClass("is-success");

        $("#SetPoint").text( AddComma(PointChargeAmount) );
        $("#SetAmount").text( AddComma(PointChargeAmount)+"원" );
    });
    /*******************************/
    $("#BTN_Recharge_Go").on('click',function (event) {
        if ( PointChargeAmount == 0 ) {
            alert("충전 금액을 선택하여 주시기 바랍니다.");
            return;
        }

        PayType = $("#PointChargeType input[name='PG_MID']:checked").val();
        if( PayType === undefined ) {
            alert("결제 방식을 선택하여 주시기 바랍니다.");
            return;
        }

        var SNDList = {};
        SNDList.PointChargeAmount = PointChargeAmount;
        LockScreen();
        $.post("/processing/com_proc_point_charge.do", SNDList, function(result) {
            UnLockScreen();
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            } else {
                $("#LIPoint").text("Point "+AddComma(result.point));
                UserPoint = result.point;
                if ( isMyPage == 1 ) $("#MyPoint").text( AddComma(UserPoint) ); // MyPage
            } 
            $( "#BTN_Recharge_Cancel" ).trigger( "click" );
        });
    });
