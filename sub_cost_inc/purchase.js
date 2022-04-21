    /**********************************************************************/
    /********************** Quotation *************************************/
    /******************** Before ***************************************/
    $("#BTN_Purchase_Before").on('click', function(e) { // Close Quotation
        $("#QuotationLock").css('display', "none");
        $("#PurchaseSection").css('display', "none");
    });

    var isMyPage=0;
<? include "sub_cost_inc/purchase_point.js" ?>

    /*******************************/
    $("#BTN_PayDoc").on('click',function (e) {
        if ( Trans_QAPremium == 1 ) {
            if ( $("#Select_Premium option:selected").val() == '-' ) {
                alert("[전문 분야]를 선택하여 주시기 바랍니다.");
                return;
            }
        }
        if ( Trans_Type < 1 ) {
            alert("서비스 유형을 선택하여 주시기 바랍니다.");
            return;
        }

        PTypeVal = 0;
        PayType = $("#isPayDocArea input[name='PG_MID']:checked").val();
        if( PayType === undefined ) {
            alert("결제 방식을 선택하여 주시기 바랍니다.");
            return;
        }
        if ( PayType == "point" ) {
            if ( UserPoint < TotalCost ) {
                NeedPoint = parseInt(TotalCost)-parseInt(UserPoint);
                alert("포인트 "+AddComma(NeedPoint)+"원이 부족합니다. 충전하신 후 결제 바랍니다.");
                return;
            }
            PTypeVal = 1; //포인트 결제
        }
        else if ( PayType == "card" ) PTypeVal = 2; //카드결제
        else if ( PayType == "bank" )  PTypeVal = 3; //실시간 계좌이체
        //else if ( PayType == "nxhp_pl_il" ) PTypeVal = 4; //폰 결제
        //else if ( PayType == "bank" )       PTypeVal = 5; //무통장 입금

        Proc = "/processing/com_proc_purchase_after.do";

        var SNDList = {};
        
        SNDList.BizType    = BizType;
        SNDList.Trans_Type = Trans_Type;
        SNDList.AI_UType   = 0;
        SNDList.Layout     = Trans_Layout;
        SNDList.QPremium   = Trans_QAPremium;
        SNDList.Urgent     = Trans_Urgent;
        SNDList.ExpertCategory = $("#Select_Premium option:selected").val();
        SNDList.TotalCost = TotalCost;
        SNDList.PredictionTime = PredictionTime;

        SNDList.PTypeVal = PTypeVal;

        //console.log(SNDList);
        if(PTypeVal=="2"){
            pay(PTypeVal, 'card', BizType, TotalCost);  
        }else if(PTypeVal=="3"){
            pay(PTypeVal, 'bank', BizType, TotalCost);  
        }else if(PTypeVal=="4"){
            pay(PTypeVal, 'mobile', BizType, TotalCost);  
        }

        if ( PayType == "point" ) 
        {
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
        }
    });

    /** 결제 버튼 동작 */
    function pay(mchtType, type, bizType, price){
        var curr_date = new Date();
        var year = curr_date.getFullYear().toString();
        var month = ("0" + (curr_date.getMonth() + 1)).slice(-2).toString();
        var day = ("0" + (curr_date.getDate())).slice(-2).toString();
        var hours = ("0" + curr_date.getHours()).slice(-2).toString();
        var mins = ("0" + curr_date.getMinutes()).slice(-2).toString();
        var secs = ("0" + curr_date.getSeconds()).slice(-2).toString();
        var random4 = ("000" + Math.random() * 10000 ).slice(-4).toString();

        var prdtNm = "";
        if(BizType =="0")
            prdtNm = "문서번역";
        else if(BizType =="1")
            prdtNm = "TTS번역";
        else if(BizType =="2")
            prdtNm = "STT번역";
        else if(BizType =="3")
            prdtNm = "동영상번역";            
        else if(BizType =="4")
            prdtNm = "동시통역";            
        else if(BizType =="5")
            prdtNm = "유튜브번역";            
        
        $('#STPG_payForm [name="BizType"]').val(BizType);
        $('#STPG_payForm [name="PTypeVal"]').val(PTypeVal);        
        $('#STPG_payForm [name="Trans_Type"]').val(Trans_Type);
        $('#STPG_payForm [name="AI_UType"]').val(0);
        $('#STPG_payForm [name="Trans_Layout"]').val(Trans_Layout);
        $('#STPG_payForm [name="Trans_QAPremium"]').val(Trans_QAPremium);
        $('#STPG_payForm [name="Trans_Urgent"]').val(Trans_Urgent);
        $('#STPG_payForm [name="ExpertCategory"]').val($("#Select_Premium option:selected").val());
        $('#STPG_payForm [name="TotalCost"]').val(TotalCost);
        $('#STPG_payForm [name="PredictionTime"]').val(PredictionTime);

        $('#STPG_payForm [name="method"]').val(type);
        $('#STPG_payForm [name="order_price"]').val(price);
        $('#STPG_payForm [name="trdDt"]').val(year + month + day);	//요청일자 세팅
        $('#STPG_payForm [name="trdTm"]').val(hours + mins + secs);	//요청시간 세팅
        $('#STPG_payForm [name="plainTrdAmt"]').val(price);	//거래금액        
        $('#STPG_payForm [name="mchtTrdNo"]').val("PAYMENT" + year + month + day + hours + mins + secs + random4);//주문번호 세팅
        $('#STPG_payForm [name="pmtPrdtNm"]').val(prdtNm);

        //용도 : SHA256 해쉬 처리 및 민감정보 AES256암호화
        $.ajax({
            type : "POST",
            url : "/processing/pg/pay_encryptParams.php", 
            dataType : "json",
            data : $("#STPG_payForm").serialize(),
            success : function(rsp){
                //암호화 된 파라미터 세팅
                for(name1 in rsp.encParams) {
                    $('#STPG_payForm [name='+name1+']').val( rsp.encParams[name1] );
                };

                //가맹점 -> 세틀뱅크로 결제 요청
                SETTLE_PG.pay({
                    env : "https://npg.settlebank.co.kr",	//결제서버 URL
                    mchtId : $('#STPG_payForm [name="mchtId"]').val(),
                    method : $('#STPG_payForm [name="method"]').val(),
                    trdDt : $('#STPG_payForm [name="trdDt"]').val(),
                    trdTm : $('#STPG_payForm [name="trdTm"]').val(),
                    mchtTrdNo : $('#STPG_payForm [name="mchtTrdNo"]').val(),
                    mchtName : $('#STPG_payForm [name="mchtName"]').val(),
                    mchtEName : $('#STPG_payForm [name="mchtEName"]').val(),
                    pmtPrdtNm : $('#STPG_payForm [name="pmtPrdtNm"]').val(),
                    trdAmt : $('#STPG_payForm [name="trdAmt"]').val(),
                    mchtCustNm : $('#STPG_payForm [name="mchtCustNm"]').val(),
                    custAcntSumry : $('#STPG_payForm [name="custAcntSumry"]').val(),
                    expireDt : $('#STPG_payForm [name="expireDt"]').val(),
                    notiUrl : $('#STPG_payForm [name="notiUrl"]').val(),
                    nextUrl : $('#STPG_payForm [name="nextUrl"]').val(),
                    cancUrl : $('#STPG_payForm [name="cancUrl"]').val(),
                    mchtParam : $('#STPG_payForm [name="mchtParam"]').val(),
                    cphoneNo : $('#STPG_payForm [name="cphoneNo"]').val(),
                    email : $('#STPG_payForm [name="email"]').val(),
                    pktHash : rsp.hashCipher,	//SHA256 처리된 해쉬 값 세팅
                    
                    ui :{
                        type:"iframe",	//popup, iframe, self, blank
                        width: "430",	//popup창의 너비
                        height: "660"	//popup창의 높이
                    }
                }, function(rsp){	
                    //iframe인 경우 전달된 결제 완료 후 응답 파라미터 처리
                    console.log(rsp);
                });
            },
            error : function(){
                alert("에러 발생");
            },
        });
    
        return false;
    }


    
    