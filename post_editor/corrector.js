var trans_type=0;
var srcLang=0;

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
    /*
    TAreaID = document.getElementById("SrcTextArea");

    var SArray=new Array();
    var array = TAreaID.value.split("\n");
    for (i=0,j=0; i<array.length; i++) {
        buf = trim(array[i]);
        if (buf.length < 1) continue;
        SArray[j] = buf; j++;
    }
    
    MText = "";
    for (IDX=0; IDX<SArray.length; IDX++) {
        if ( IDX > 0  ) MText += "\n\n";
        MText += SArray[IDX];
    }
    TAreaID.value = MText;*/
    resize( document.getElementById("SrcTextArea") );
}

/*************** get Saved MT Text *****************************/
function Get_Origin_Text() {
    var SNDList = {};
    SNDList.svc_type = BIZ;
    SNDList.Project = PJT;
    LockScreen();
    $.post("/processing/expert_get_text.do", SNDList, function(result) {
        if (result.isOK == 0) {
            $("#MessageDiv").text("에러가 발생하였습니다.\n" + result.RText);
        }
        else {
            trans_type = parseInt(result.trans_type);
            srcLang = result.srcLang;

            $("#STTAudio").attr("src", "/file_upload/"+result.job_name+".mp3");

            $("#SrcTextArea").val( result.SrcText );
            $("#SrcLang").text( result.SrcLangText );
            resize( document.getElementById("SrcTextArea") );
            UnLockScreen();
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
function Save_Sentence(isTMP) {
    TAreaID = document.getElementById("SrcTextArea");

    var SArray=new Array();
    var array = TAreaID.value.split("\n");
    for (i=0,j=0; i<array.length; i++) {
        buf = trim(array[i]);
        if (buf.length < 1) continue;
        SArray[j] = buf; j++;
    }
    
    // MText = "";
    // for (IDX=0; IDX<SArray.length; IDX++) {
    //     if ( IDX > 0  ) MText += "\n";
    //     MText += SArray[IDX];
    // }

    var SNDList = {};
    SNDList.isTMP = isTMP;
    SNDList.svc_type = BIZ;
    SNDList.Project = PJT;
    SNDList.trans_type = trans_type;
    SNDList.srcLang = srcLang;
    SNDList.SrcArray = SArray;
    $.post("/processing/expert_save_text.do", SNDList, function(result) {
        if (result.isOK == 0) {
            $("#MessageDiv").text("오류 발생 : " + result.RText);
        }
        else {
            $("#MessageDiv").text(result.RText);
            if ( isTMP == 0 ) {
                window.opener.$("#subMenu_1").trigger('click');
                window.close();
            }
            else setTimeout(function() { Clear_Message(); }, 3000);
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
    //     $('#BTN_Temp_Save').attr('disabled', true);
    //     $('#BTN_Save_End').attr('disabled', true);
    // }
    
    $("#BTN_Auto_Split").on('click',function (event) {
        Text_Split();
    });
    $("#BTN_Temp_Save").on('click',function (event) {
        Save_Sentence( 1 );
    });
    $("#BTN_Save_End").on('click',function (event) {
        Save_Sentence( 0 );
    });

    $(".stepWork").hover(function(){
        $(".popupInfoTransBox").toggleClass("active");
    })

    Get_Origin_Text();
});
