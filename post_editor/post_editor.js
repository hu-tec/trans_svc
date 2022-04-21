var trans_type=0;
var srcLang=0;
var tgtLang=0;
var Curr_AIName="";

/***********************************************************/
function TextSplit(SrcText, Delimiter) {
    var sentences = SrcText.split(Delimiter);
    var lines = [];
    for(var i = 0; i < sentences.length; i++) 
        lines.push(sentences[i].trim());
    return lines.join(Delimiter+'\n');
}
/***********************************************************/
function Text_Split() {
    TAreaID = document.getElementById("SrcTextArea");

    TmpText = TAreaID.value;
    TmpText = TextSplit(TmpText, '.');
    TmpText = TextSplit(TmpText, '!');
    TmpText = TextSplit(TmpText, '?');
    TmpText = TextSplit(TmpText, '。');
    TmpText = TextSplit(TmpText, '？');
    TmpText = TextSplit(TmpText, '！');
    TAreaID.value = TmpText;

    // var SArray=new Array();
    // var array = TmpText.split("\n");
    // for (i=0,j=0; i<array.length; i++) {
    //     buf = trim(array[i]);
    //     if (buf.length < 1) continue;
    //     SArray[j] = buf; j++;
    // }
    
    // MText = "";
    // for (IDX=0; IDX<SArray.length; IDX++) {
    //     if ( IDX > 0  ) MText += "\n";
    //     MText += SArray[IDX];
    // }
    // TAreaID.value = MText;
    resize( document.getElementById("SrcTextArea") );
}

/***********************************************************/
function Make_Sentence_Table_Sub(SArray, TArray) {
    TID = document.getElementById("ED_TABLE");
    for (i=TID.rows.length-1;i>0; i--) {
        TID.deleteRow(i);
    }
    for (IDX=0; IDX<SArray.length; IDX++) {
        OneRow = TID.insertRow();
        OneRow.className = "class";
        OneRow.setAttribute("class","row");
        for (i=0; i<3; i++) {
            OneCell = OneRow.insertCell(i);
            //OneCell.style.verticalAlign="top";
            if (i == 0 ) ELE = '<div contentEditable="false" class="div-edit">'+TArray[IDX]+'</div>';
            else if (i == 1 ) ELE = '<div contentEditable="true" class="div-edit" style="border:1px solid #F6DDCC;">'+SArray[IDX]+'</div>';
            else if (i == 2 ) ELE = '<div contentEditable="true" class="div-edit" style="border:1px solid #F6DDCC;">'+TArray[IDX]+'</div>';
            OneCell.innerHTML = ELE;
        }
    }
}
/*************** STEP 2 : get Saved MT Text from Expert PE *****************************/
function Get_PostEditor_Text() {
    var SNDList = {};
    SNDList.svc_type = BIZ;
    SNDList.Project = PJT;
    SNDList.srcLang = srcLang;
    SNDList.tgtLang = tgtLang;
    $.post("/processing/expert_get_sentence.do", SNDList, function(result) {
        if (result.isOK == 0) {
            MsgOutput("에러가 발생하였습니다.\n" + result.RText, 10);
        }
        else if (result.isOK == 1) { // No data
            $("#BTN_Auto_Split").removeAttr("disabled");
        }
        else {
            $("#SrcTextArea").attr("disabled", true);

            $("#BTN_TArea_Toggle").trigger('click');
            Make_Sentence_Table_Sub(result.SrcRec, result.TgtRec);
            $("#DIV_ED").css("display","flex");

            //if ( window.opener.UserType != 99 ) {
                $("#BTN_Auto_Split").attr("disabled", true);
                $("#BTN_Auto_Split").addClass('btn-white');

                $('#AI_Trans_Select').attr('disabled', true);
                $('#AI_Trans_Select').css('background', 'white');
                $('#AI_Trans_Select').css('color', 'black');
                if ( Curr_AIName.length>1 )
                    $('#AI_Trans_Select option:selected').text( '②'+Curr_AIName );
                
                $("#BTN_Temp_Save").removeAttr("disabled");
                $("#BTN_Temp_Save").removeClass('btn-white');
                $("#BTN_Temp_Save").addClass('btn-green');

                $("#BTN_Save_End").removeAttr("disabled");
                $("#BTN_Save_End").removeClass('btn-white');
                $("#BTN_Save_End").addClass('btn-red');
            //}
        }
        UnLockScreen();
    });
}

/*************** STEP 1 : get Saved MT Text *****************************/
function Get_Origin_Text() {
    var SNDList = {};
    SNDList.svc_type = BIZ;
    SNDList.Project = PJT;
    LockScreen();
    $.post("/processing/expert_get_text.do", SNDList, function(result) {
        if (result.isOK == 0) {
            MsgOutput("에러가 발생하였습니다.\n" + result.RText, 10);
            UnLockScreen();
        }
        else {
            trans_type = parseInt(result.trans_type);
            srcLang = result.srcLang;
            tgtLang = result.tgtLang;

            if ( BIZ != 1 ) { // is not TTS
                $("#STTAudio").attr("src", "/file_upload/"+result.job_name+".mp3");
                $("#STTAudio").removeAttr("hidden");
            }

            $("#SrcTextArea").val( result.SrcText );
            $("#TgtTextArea").val( result.TgtText );

            if ( result.ai_api != "-" ) {
                $('#AI_Trans_Select').val( result.ai_api );
                Curr_AIName = $('#AI_Trans_Select option:selected').text();
            }

            $("#SrcLang").html( "<font color='blue'><b>"+result.SrcLangText+"</b></font>" );
            $("#TgtLang").html( "<font color='blue'><b>"+result.TgtLangText+"</b></font>" );

            resize( document.getElementById("SrcTextArea") );
            resize( document.getElementById("TgtTextArea") );

            setTimeout(function() { Get_PostEditor_Text(); }, 10);
        }
    });
}

/*************** AI MT *****************************/
function Proc_AI_MT(MTCloud) {
    TAreaID = document.getElementById("SrcTextArea");

    var SArray=new Array();
    var array = TAreaID.value.split("\n");
    for (i=0,j=0; i<array.length; i++) {
        buf = trim(array[i]);
        if (buf.length < 1) continue;
        SArray[j] = buf; j++;
    }

    var SNDList = {};
    SNDList.MTCloud = MTCloud; // Google(01), Naver(02), Systran(04)
    SNDList.svc_type = BIZ;
    SNDList.Project = PJT;
    SNDList.srcLang = srcLang;
    SNDList.tgtLang = tgtLang;
    SNDList.SrcArray = SArray;

    LockScreen();
    $.post("/processing/expert_text_trans.do", SNDList, function(result) {
        if (result.isOK == 0) {
            MsgOutput(result.RText, 10);
            if ( MTCloud=='02' && result.ErrorCode.length > 0 ) { // Naver
                if ( result.ErrorCode == 'N2MT02' ) {
                    alert("Naver 번역 : 선택한 '원문 언어'는 지원하지 않습니다.\n\nGoogle번역을 이용하여 주시기 바랍니다.");
                }
                else if ( result.ErrorCode == 'N2MT04' ) {
                    alert("Naver 번역 : 선택한 '번역 언어'는 지원하지 않습니다.\n\nGoogle번역을 이용하여 주시기 바랍니다.");
                }
            }
            else if ( MTCloud=='04' && result.ErrorCode.length > 0 ) { // Systran
                alert("Systran 번역 : 선택한 '언어쌍'은 지원하지 않습니다.\n\nGoogle번역을 이용하여 주시기 바랍니다.");
            }

            $('#AI_Trans_Select').val( '-' );
            UnLockScreen();
        }
        else {
            setTimeout(function() { Get_PostEditor_Text(); }, 10);
        }
    });
}
/********************************************/
function resize(obj) {
    obj.style.height = '1px';
    obj.style.height = (12 + obj.scrollHeight) + 'px';
}
/*************** get Saved MT Text *****************************/
function Clear_Message() {
    $("#MessageDiv").text("");
}
function MsgOutput( Text, WTimeSec ) {
    $("#MessageDiv").text( Text );
    setTimeout(function() { Clear_Message(); }, WTimeSec*1000);
}
function Save_Sentence(isTMP) {
    Len = $('#ED_TABLE tr').length;
    if ( Len < 2 ) {
        alert("저장할 문장이 없습니다.");
        return;
    }

    var OriArray = new Array();
    var ResArray = new Array();
    j=0; k=0;
    for (i=1; i<Len; i++) {
        SrcText = $('#ED_TABLE tr:eq('+i+')>td:eq(1)').text();
        SrcText = trim(SrcText);
        if ( SrcText.length > 0 ) {
            OriArray[j] = SrcText; j++;
        }

        TgtText = $('#ED_TABLE tr:eq('+i+')>td:eq(2)').text();
        TgtText = trim(TgtText);
        if ( TgtText.length > 0 ) {
            ResArray[k] = TgtText; k++;
        }
    }

    if ( OriArray.length != ResArray.length ) {
        alert("원문과 번역문의 개수가 다릅니다.");
        return;
    }

    var SNDList = {};
    SNDList.isTMP = isTMP;
    SNDList.svc_type = BIZ;
    SNDList.Project = PJT;
    SNDList.trans_type = trans_type;
    SNDList.SrcArray = OriArray;
    SNDList.TgtArray = ResArray;
    SNDList.srcLang = srcLang;
    SNDList.tgtLang = tgtLang;

    $.post("/processing/expert_save_text.do", SNDList, function(result) {
        if (result.isOK == 0) {
            MsgOutput("오류 발생 : " + result.RText, 10);
        }
        else {
            MsgOutput(result.RText, 10);
            if ( isTMP == 0 ) {
                window.opener.$("#subMenu_1").trigger('click');
                window.close();
            }
        }
    });
}
/***********************************************************/
function AddOpt(id, ListData) {
    ELSEL = document.getElementById(id);
    for(var i in ListData) {
        ELOpt = document.createElement('option');
        ELOpt.value = ListData[i].code;
        ELOpt.text  = ListData[i].text;
        ELSEL.appendChild(ELOpt);
    }
}
/****************************************************/
function GetCode() {
    var SNDList = {};
    SNDList.isAll = 0;
    SNDList.Name = "AITransCode";
    $.post("/processing/com_proc_get_code.do", SNDList, function(result) {
        if (result.isOK == 0) {
            alert("에러가 발생하였습니다.\n" + result.RText);
        } else { 
            AddOpt("AI_Trans_Select", result.CodeList);
            //STEP 1  & 2
            setTimeout(function() { Get_Origin_Text(); }, 10);
        } 
    });
}
/***********************************************************/
$(document).ready(function() {
    document.addEventListener('keydown', function(event) {
        if(event.target.tagName=="DIV"){
          if (event.keyCode === 13) {
            event.preventDefault();
          }
        };
    }, true);

    // if ( window.opener.UserType == 99 ) { // Manager
    //     $('#BTN_Auto_Split').attr('disabled', true);

    //     $("#AI_Trans_Select").attr('disabled', true);
    //     $('#AI_Trans_Select').css('background', '#982dbc');
    //     $('#AI_Trans_Select').css('color', 'white');

    //     $('#BTN_Temp_Save').attr('disabled', true);
    //     $("#BTN_Temp_Save").removeClass('btn-white');
    //     $("#BTN_Temp_Save").addClass('btn-green');

    //     $('#BTN_Save_End').attr('disabled', true);
    //     $("#BTN_Save_End").removeClass('btn-white');
    //     $("#BTN_Save_End").addClass('btn-red');
    // }

    $("#BTN_TArea_Toggle").on('click',function (e) {
        if ( $(this).hasClass('btn-gray') ) {
            $(this).removeClass('btn-gray');
            $(this).addClass('btn-black');
            $(this).text("텍스트 창 열기");
            $("#DIV_TextArea").css("display","none"); 
        }
        else {
            $(this).removeClass('btn-black');
            $(this).addClass('btn-gray');
            $(this).text("텍스트 창 숨기기");
            $("#DIV_TextArea").css("display","flex"); 
        }
    });
    $("#BTN_Auto_Split").on('click',function (e) {
        //if ( window.opener.UserType == 99 ) return;
        alert("자동으로 완벽하게 문장 단위로 분리되지 않습니다.\nAI 번역전에 문장 단위로 분리되었는지 확인 및 수정해 주시기 바랍니다.");
        Text_Split();
        $("#AI_Trans_Select").removeAttr("disabled");
        $('#AI_Trans_Select').css('background', '#982dbc');
        $('#AI_Trans_Select').css('color', 'white');
        MsgOutput("원문의 내용을 확인한 후 AI번역을 진행하시기 바랍니다. 다시 번역할 수 없습니다.", 10);
    });
    $('#AI_Trans_Select').on('change', function(e) {
        //if ( window.opener.UserType == 99 ) return;
        
        SelVal = $(this).val();
        if ( SelVal == '-') {
            alert("AI번역 서비스를 선택하여 주시기 바랍니다.");
            return;
        }

        Curr_AIName = $('option:selected', this).text();

        if ( SelVal== '01' || SelVal== '02' || SelVal== '04' ) { // Google, Naver, Systran
            Proc_AI_MT(SelVal);
        }
        else {
            alert("곧 서비스 예정입니다.\n현재는 Google, Naver의 AI번역을 사용할 수 있습니다.");
            $(this).val("-");
        }
    });
    $("#BTN_Temp_Save").on('click',function (e) {
        //if ( window.opener.UserType == 99 ) return;
        Save_Sentence( 1 );
    });
    $("#BTN_Save_End").on('click',function (e) {
        //if ( window.opener.UserType == 99 ) return;
        Save_Sentence( 0 );
    });

    $(".stepWork").hover(function(){
        $(".popupInfoTransBox").toggleClass("active");
    })

    if ( window.opener.UserCheck == "isOn" ) {
        GetCode();
    }
});
