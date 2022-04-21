/** pay_receiveResult.php로부터 응답 값을 받아와서 main폼에 세팅 */
function rstparamSet(rslt){
    $('#STPG_payForm [name="respMchtId"]').val(rslt.mchtId);
    $('#STPG_payForm [name="respOutStatCd"]').val(rslt.outStatCd);
    $('#STPG_payForm [name="respOutRsltCd"]').val(rslt.outRsltCd);
    $('#STPG_payForm [name="respOutRsltMsg"]').val(rslt.outRsltMsg);
    $('#STPG_payForm [name="respMethod"]').val(rslt.method);
    $('#STPG_payForm [name="respMchtTrdNo"]').val(rslt.mchtTrdNo);
    $('#STPG_payForm [name="respMchtCustId"]').val(rslt.mchtCustId);
    $('#STPG_payForm [name="respTrdNo"]').val(rslt.trdNo);
    $('#STPG_payForm [name="respTrdAmt"]').val(rslt.trdAmt);
    $('#STPG_payForm [name="respMchtParam"]').val(rslt.mchtParam);
    $('#STPG_payForm [name="respAuthDt"]').val(rslt.authDt);
    $('#STPG_payForm [name="respAuthNo"]').val(rslt.authNo);
    $('#STPG_payForm [name="respIntMon"]').val(rslt.intMon);
    $('#STPG_payForm [name="respFnNm"]').val(rslt.fnNm);
    $('#STPG_payForm [name="respFnCd"]').val(rslt.fnCd);
    $('#STPG_payForm [name="respPointTrdNo"]').val(rslt.pointTrdNo);
    $('#STPG_payForm [name="respPointTrdAmt"]').val(rslt.pointTrdAmt);
    $('#STPG_payForm [name="respRtNowDiscountAmt"]').val(rslt.RtNowDiscountAmt);
    $('#STPG_payForm [name="respAlacDiscountAmt"]').val(rslt.AlacDiscountAmt);
    $('#STPG_payForm [name="respCardTrdAmt"]').val(rslt.cardTrdAmt);
    $('#STPG_payForm [name="respVAcntNo"]').val(rslt.vAcntNo);
    $('#STPG_payForm [name="respExpireDt"]').val(rslt.expireDt);
    $('#STPG_payForm [name="respCphoneNo"]').val(rslt.cphoneNo);
    $('#STPG_payForm [name="respBillkey"]').val(rslt.billkey);
}
/** main폼에 세팅된 응답 값 출력 */
function goResult(){        
    if($('#STPG_payForm [name="respOutStatCd"]').val()=="0021")
    {
        PTypeVal = 0;
        PayType = $("#isPayDocArea input[name='PG_MID']:checked").val();
        if ( PayType == "nxca_jt_il" ) PTypeVal = 2; //카드결제
        else if ( PayType == "nx_mid_il" )  PTypeVal = 3; //실시간 계좌이체
        else if ( PayType == "nxhp_pl_il" ) PTypeVal = 4; //폰 결제
        else if ( PayType == "bank" )       PTypeVal = 5; //무통장 입금

        Proc = "/processing/com_proc_purchase_after.do";

        var SNDList = {};
        
        
        SNDList.BizType    = $('#STPG_payForm [name="BizType"]').val();
        SNDList.Trans_Type = $('#STPG_payForm [name="Trans_Type"]').val();
        SNDList.AI_UType   = $('#STPG_payForm [name="AI_UType"]').val();
        SNDList.Layout     = $('#STPG_payForm [name="Trans_Layout"]').val();
        SNDList.QPremium   = $('#STPG_payForm [name="Trans_QAPremium"]').val();
        SNDList.Urgent     = $('#STPG_payForm [name="Trans_Urgent"]').val();
        SNDList.ExpertCategory = $('#STPG_payForm [name="ExpertCategory"]').val();
        SNDList.TotalCost = $('#STPG_payForm [name="TotalCost"]').val();
        SNDList.PredictionTime = $('#STPG_payForm [name="PredictionTime"]').val();;

        SNDList.PTypeVal = $('#STPG_payForm [name="PTypeVal"]').val();;
            
        LockScreen();
        $.post(Proc, SNDList, function(result) {
            UnLockScreen();
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            } else {
                $("#LIPoint").text("Point "+AddComma(result.point));
                UserPoint = result.point;

                Trans_Type = 0;
                Trans_Layout = 0;
                Trans_QAPremium = 0;
                Trans_Urgent = 0;


                alert("결제가 완료되었습니다.\n[마이페이지]에서 진행사항을 조회하여 주시기 바랍니다.");
                //setTimeout(function() { UpdateDocTranTable(); }, 10);
                window.location.reload();
            } 
        });
    } else { 
        //UnLockScreen();
        window.location.reload();
    }
}

/******************** Lock / UnLock ***************************************/
function LockScreen() {
    document.querySelector(".d-flex").classList.add("active");
    document.querySelector(".loading").classList.add("active");
}
function UnLockScreen() {
    document.querySelector(".d-flex").classList.remove("active");
    document.querySelector(".loading").classList.remove("active");
}
