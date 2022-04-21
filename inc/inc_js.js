/***********************************************************/
function trim(STR) {
    return STR.replace(/(^\s*)|(\s*$)/gi, '');
}

/***********************************************************/
function AddComma(OVal) {
    CVal = parseInt(OVal);
    if ( CVal == 0 ) return  "-";
    return CVal.toLocaleString("ko-KR");
}

/***********************************************************/
function ConvertTime(OVal) {
    Seconds = parseInt(OVal);
    if ( Seconds == 0 ) return  "-";
    hour = parseInt(Seconds/3600) < 10 ? '0'+ parseInt(Seconds/3600) : parseInt(Seconds/3600); 
    min = parseInt((Seconds%3600)/60) < 10 ? '0'+ parseInt((Seconds%3600)/60) : parseInt((Seconds%3600)/60); 
    sec = Seconds % 60 < 10 ? '0'+Seconds % 60 : Seconds % 60;

    RetStr = "";
    if ( hour > 0 ) RetStr += hour + ":";
    RetStr += min + ":" + sec;
    return RetStr;
}

/****************************************************/
// for doc_trans & my_payment
function Display_Cost(ID, Val_Cost, isRet=0) {
    TVal = "-";
    TotalCost = parseInt(Val_Cost);
    if ( TotalCost > 0 ) TVal = "₩"+AddComma(TotalCost);

    if ( isRet ) return TVal;
    else $(ID).text(TVal);
}

function Display_Time(ID, Val_PTime, isRet=0) {
    TVal = "-";
    PredictionTime = parseInt(Val_PTime);
    DisplayTime=0;
    H1 = 60*60;
    D1 = H1 * 8;
    if ( PredictionTime == 0 ) {}
    else if ( PredictionTime < H1 ) { // 분
        DisplayTime = (PredictionTime/60).toFixed();
        TVal = "< "+AddComma(DisplayTime)+"분";
    }
    else if ( PredictionTime < D1 ) { // 시간
        DisplayTime = (PredictionTime/H1).toFixed();
        TVal = "< "+AddComma(DisplayTime)+"시간";
    }
    else {
        DisplayTime = (PredictionTime/D1).toFixed();
        TVal = "< "+AddComma(DisplayTime)+"일";
    }
    
    // if ( PredictionTime < 3600 )
    //     TVal = "최대 "+AddComma(DisplayTime)+"분 (" + PredictionTime + ")";
    // else
    //     TVal = "최대 "+AddComma(DisplayTime)+"시간 (" + PredictionTime + ")";

    if ( isRet ) return TVal;
    else $(ID).text(TVal);
}
/****************** Service Option Return **********************************/
function BizCase(svctype) {
    ret='';
    if ( svctype == 0 ) ret = "문서";
    else if ( svctype == 1 ) ret = "TTS";
    else if ( svctype == 2 ) ret = "STT";
    else if ( svctype == 3 ) ret = "영상";
    else if ( svctype == 4 ) ret = "동시통역";
    else if ( svctype == 5 ) ret = "유튜브";
    return ret;
}
/****************** Service Option Return **********************************/
function ServiceType(svctype, trans_type) {
    ret='';
    if ( trans_type == 1 ) ret = "Basic";
    else if ( trans_type == 2 ) ret = "Standard";
    else if ( trans_type == 3 ) ret = "Deluxe";
    else if ( trans_type == 4 ) ret = "Premium";
    return ret;
}
/****************** Service Option Return **********************************/
function ServiceOption(urgent, qa_premium, expert_category, layout) {
    ret=""; Cnt=0;
    if ( urgent == 1 ) { 
        ret += "<font class='txt-red'>긴급</font>"; Cnt++;
    }
    if ( qa_premium == 1 ) { 
        if (Cnt>0) ret += "<br>";
        ret += "<font class='txt-blue'>전문감수:"+expert_category+"</font>"; Cnt++;
    }
    if ( layout == 1 ) { 
        if (Cnt>0) ret += "<br>";
        ret += "<font class='txt-green'>문서형식유지</font>"; Cnt++;
    }
    return ret;
}
/****************** State Return **********************************/
function StatusAttr(svctype, status) {
    SetColor = ""; SetText = "준비중";
    if ( svctype == 0 ) { // DOC
        if ( status == 0 )        { SetColor = ""; SetText = "업로드 완료"; }
        else if ( status == 1 )   { SetColor = "txt-green"; SetText = "문서 분석중"; }
        else if ( status == 2 )   { SetColor = "txt-green"; SetText = "분석 완료"; }
    }
    else if ( svctype == 1 ) { // TTS
        if ( status == 0 )        { SetColor = ""; SetText = "작성중"; }
        else if ( status == 1 )   { SetColor = "txt-green"; SetText = "작성중"; }
        else if ( status == 2 )   { SetColor = "txt-green"; SetText = "견적중"; }
    }
    else if ( 2 <= svctype && svctype <= 5 ) { // STT, VIDEO, S2S, YOUTUBE
        if ( status == 0 )        { SetColor = ""; SetText = "업로드 완료"; }
        else if ( status == 1 )   { SetColor = "txt-green"; SetText = "음성 분석중"; }
        else if ( status == 2 )   { SetColor = "txt-green"; SetText = "음성 분석완료"; }
        else if ( status == 10 )  { SetColor = "txt-blue"; SetText = "영상받는 중"; }
    }

    if ( status == 3 )   { SetColor = "txt-green"; SetText = "결제 완료"; }
    else if ( status == 11 )  { SetColor = "txt-blue"; SetText = "AI처리 중"; }
    else if ( status == 50 )  { SetColor = "txt-purple"; SetText = "휴먼대기중"; }
    else if ( status == 51 )  { SetColor = "txt-purple"; SetText = "휴먼작업중"; }
    else if ( status == 52 )  { SetColor = "txt-purple"; SetText = "휴먼완료"; }
    else if ( status == 100 ) { SetColor = "txt-red"; SetText = "종료"; }
    
    else if ( status == 900 ) { SetColor = "txt-red"; SetText = "취소됨(지원불가)"; }
    else if ( status == 901 ) { SetColor = "txt-red"; SetText = "취소됨(오류발생)"; }

    return { color:SetColor, text:SetText };
}
/****************************************************/
/****************** Download selected File **********************************/
function FileDownload(tmpFileName, oriFileName, isResult=1 )  {
    //alert(tmpFileName + " : " + oriFileName);
    var form = $('<form></form>');
    form.attr('action', './processing/com_proc_file_down.do');
    form.attr('method', 'post');

    form.appendTo('body');
    var tmp = $("<input type='hidden' value='"+tmpFileName+"' name='tmpFileName'>");
    var ori = $("<input type='hidden' value='"+oriFileName+"' name='oriFileName'>");
    var opt = $("<input type='hidden' value='"+isResult+"'    name='isResult'>");
    form.append(tmp);
    form.append(ori);
    form.append(opt);
    
    form.submit();
}
