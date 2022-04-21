var TextMaxLen=5000;
var Timer;
var Status=0;

var isFirst=1;

var Trans_Type=0;
var Trans_Layout    = 0;
var Trans_QAPremium = 0;
var Trans_Urgent    = 0;

var TotalCost=0;
var PredictionTime=0;

var isTrans=0;

var isCalculation=0;

var BizType = 1; // TTS

var isChangeServiceText = 0;

/******************** Lock / UnLock ***************************************/
function LockScreen() {
    document.querySelector(".d-flex").classList.add("active");
    document.querySelector(".loading").classList.add("active");
}
function UnLockScreen() {
    document.querySelector(".d-flex").classList.remove("active");
    document.querySelector(".loading").classList.remove("active");
}
/****************************************************/
function Get_Saved_Text(PJTName) {
    var SNDList = {};
    LockScreen();
    $.post("/processing/text_proc_get.do", SNDList, function(result) {
        UnLockScreen();
        if (result.isOK == 0) {
            alert("에러가 발생하였습니다.\n" + result.RText);
        } else { 
            $("#SrcTextArea").val(result.SrcText);
            $('#text_cnt').text($("#SrcTextArea").val().length+"/"+TextMaxLen);
        }
    });
}

/****************************************************/
function UpdateDocTranTable() {
    var SNDList = {};
    LockScreen();
    Table = $('#txttsTransList').DataTable( {
        "ajax": {
            "type" : "POST",
            "url" : "/processing/tts_proc_list.do",
            "data" : SNDList,
            "dataType": "JSON"
        },
        "autoWidth": true,
        "destroy": true,
        "pageLength": 10,
        //"lengthMenu": [10, 20, 50, 100],
        "fixedHeader" : true,
        "bLengthChange": false,
        "bPaginate": false,
        "bFilter": false,
        "ordering": false,
        'paging': false, 
        "info": false,
        "columns": [
            { "data": "seq" }, // 0 SEQ
            { "data": "projectname" }, // 1
            { "data": "srcLang" }, // 2
            { "data": "tgtLang" }, // 3
            { "data": "numofchar" }, // 4
            { "data": "cost" }, // 5
            { "data": "status" }, // 6
            { "data": "src_audio" }, // 7
            { "data": "tgt_audio" }, // 8
            { "data": "trans_type" }, // 9
            { "data": "trans_quality" }, // 10
            { "data": "urgent" }, // 11
            { "data": "prediction_time" }, // 12
            { "data": "expert_category" }, // 13
            { "data": "exist_file_1" }, // 14
            { "data": "exist_file_2" }, // 15
            { "data": "sdate" }, // 16
        ],
        'columnDefs': [
            {'targets': 0, 'className': 'dt-body-center', 'visible': false }, // seq
            {'targets': 1, 'className': 'dt-body-center', 'visible': false }, // projectname
            {'targets': 2, 'className': 'dt-body-center',  // 언어
                'render': function (data, type, full, meta){ 
                    Status = full.status;
                    $("#SrcLang").val(full.srcLang);
                    $("#TgtLang").val(full.tgtLang);
                    if ( full.tgtLang == '-' )
                        SET = $("#SrcLang option:selected").text() + "(TTS만)";
                    else 
                        SET = $("#SrcLang option:selected").text() + " > " + $("#TgtLang option:selected").text() + "(번역포함)";
                    return SET;
                }
            }, 
            {'targets': 3, 'className': 'dt-body-center', 'visible': false }, // 대상 언어
            {'targets': 4, 'className': 'dt-body-center', // numofchar
                'render': function (data, type, full, meta) {
                    return AddComma(full.numofchar);
                }
            },
            {'targets': 5, 'className': 'dt-body-center', // Cost
                'render': function (data, type, full, meta) {
                    return Display_Cost("", full.cost, 1);
                }
            },
            {'targets': 6, 'className': 'dt-body-center', // status
                'render': function (data, type, full, meta) { 
                    ret = StatusAttr(1, parseInt(full.status));
                    return "<font class='"+ret.color+"'>"+ret.text+"</font>";
                }
            },
            {'targets': 7, 'className': 'dt-body-center', 'visible': false }, // src_audio
            {'targets': 8, 'className': 'dt-body-center', 'visible': false }, // tgt_audio
            {'targets': 9, 'className': 'dt-body-center', 'visible': false }, // trans_type
            {'targets': 10, 'className': 'dt-body-center', 'visible': false }, // trans_quality
            {'targets': 11, 'className': 'dt-body-center', 'visible': false }, // urgent
            {'targets': 12, 'className': 'dt-body-center', 'visible': false }, // prediction_time
            {'targets': 13, 'className': 'dt-body-center', 'visible': false }, // expert_category
            {'targets': 14, 'className': 'dt-body-center', 'visible': false }, // exist_file_1
            {'targets': 15, 'className': 'dt-body-center', 'visible': false }, // exist_file_2
            {'targets': 16, 'className': 'dt-body-center',  // sdate
                'render': function (data, type, full, meta) { 
                    SET = "";
                    if ( Status <= 2 )
                        SET = '<button type="button" class="btn-s btn-purple" Del_PrjName="'+full.projectname+'">삭제</button>';
                    return SET;
                }
            },
        ],
        "initComplete": function(settings, json){
            UnLockScreen();
            $(".circleOnOff").removeClass('active');

            TotRecCnt = Table.rows().data().length;
            if ( TotRecCnt < 1 ) {
                $("#SrcLang").val("at");
                $("#TgtLang").val("-");

                $("#SrcTextArea").val("");
                $('#text_cnt').text("0/"+TextMaxLen);

                $("#PS_1").addClass('active');
                QuotationSection_ONOFF("none");
                $("#PurchaseSection").css('display', "none");
                $("#DIV_TTSList").css("display", "none");
                return;
            }

            ////// Progress Step /////////////
            if ( Status < 2 ) $("#PS_2").addClass('active');
            else if ( Status == 2 ) {
                if ( Trans_Type == 0 ) $("#PS_3").addClass('active');
                else $("#PS_4").addClass('active');
            }
            ///////////////////////////////////

            numofchar = 0;
            TotalCost = 0;

            Trans_Type      = parseInt( Table.cell( 0, 9 ).data() );
            Trans_QAPremium = parseInt( Table.cell( 0, 10 ).data() );
            Trans_Urgent    = parseInt( Table.cell( 0, 11 ).data() );

            for (i=0; i<TotRecCnt; i++) {
                numofchar += parseInt( Table.cell( i, 4 ).data() );
                TotalCost += parseInt( Table.cell( i, 5 ).data() );
                PredictionTime += parseInt( Table.cell( i, 12 ).data() );
            }

            if ( $("#TgtLang option:selected").val() != '-' ) {
                $("#TransLang").text( $("#SrcLang option:selected").text() + " > " + $("#TgtLang option:selected").text() );
                isTrans = 1;
                Select_Trans_ONOFF( 1 ); 
            }
            else {
                $("#TransLang").text( $("#SrcLang option:selected").text() );
                isTrans = 0;
                Select_Trans_ONOFF( 0 ); 
            }

            /***** For Quotation ******/
            if ( Table.cell(0, 13).data().length < 1 ) ExCategory = '-';
            else ExCategory = Table.cell(0, 13).data();
            $("#Select_Premium").val(ExCategory).prop("selected", true);

            if ( Trans_Type == 1 ) {
                Set_Add_Option(0, 0);
                Selected_Type_Switch( document.getElementById("BTNType_Basic") );
            }
            else if ( Trans_Type == 2 ) {
                Set_Add_Option(0, 0);
                Selected_Type_Switch( document.getElementById("BTNType_STandard") );
            }
            else if ( Trans_Type == 3 || Trans_Type == 4 ) {
                Set_Add_Option(1, 1);
                if ( Trans_Type == 3 ) Selected_Type_Switch( document.getElementById("BTNType_Deluxe") );
                else Selected_Type_Switch( document.getElementById("BTNType_Premium") );
            }

            if ( Trans_QAPremium == 1 ) Add_Selected_Switch( document.getElementById("BTN_Quality_Premium"), 0 ); 
            if ( Trans_Urgent == 1 )    Add_Selected_Switch( document.getElementById("BTN_Urgent"), 0 );

            if ( isFirst ) {
                Get_Saved_Text( );
                isFirst = 0;
            }

            $("#DIV_TTSList").css("display", "");
            Quotation_Section_Open();
        }
    } );
}

/***********************************************************/
function AddOpt(id, ListData) {
    ELSEL = document.getElementById(id);

    for(var i in ListData) {
        if ( id == 'TgtLang' && ListData[i].code == 'at') continue;
        ELOpt = document.createElement('option');
        ELOpt.class = "div2";
        ELOpt.value = ListData[i].code;
        ELOpt.text  = ListData[i].text;
        ELSEL.appendChild(ELOpt);
    }
}
/****************************************************/
function GetCode() {
    var SNDList = {};
    SNDList.isAll = 1;
    SNDList.Name = "LangCode";
    LockScreen();
    $.post("/processing/com_proc_get_code.do", SNDList, function(result) {
        UnLockScreen();
        if (result.isOK == 0) {
            alert("에러가 발생하였습니다.\n" + result.RText);
        } else { 
            AddOpt("SrcLang", result.CodeList);
            AddOpt("TgtLang", result.CodeList);

            if ( UserCheck == "isOn" )
                setTimeout(function() { GetExpertCode(); }, 10);
        } 
    });
}
/******************** Basic On/Off ***************************************/
function Select_Trans_ONOFF( isON ) {
    if ( isON == 0 )
        $('#BTNType_Basic').css("display", "");
    else 
        $('#BTNType_Basic').css("display", "none");
}

/******************** Check Source/Target Language ***************************************/
function Check_Lang() {
    if ( $("#SrcLang option:selected").val() == '-' ){
        alert("[원문 언어]를 선택하여 주십시오.");
        return false;
    }
    if ( isTrans ) {
        if ( $("#TgtLang option:selected").val() == '-' ){
            alert("[번역할 언어]를 선택하여 주십시오.");
            return false;
        }
        if ( $("#SrcLang option:selected").val() == $("#TgtLang option:selected").val() ){
            alert("[원문 언어]와 [번역할 언어]가 동일합니다. 다시 선택하여 주십시오.");
            return false;
        }
    }
    return true;
}

/********************  Open Quotation ***************************************/
/*************************************/
function Quotation_Section_Open() {
    //$("#SrcTextArea").attr("readonly", true);

    $('#BTNType_Basic').css("display", "block");
    $("#BTN_File_Layout").css("display", "none");

    if ( isChangeServiceText == 0 ) {
        $("#Text_Standard").html('AI TTS <img width="14px" height="14px" src="/img/plus.png"> ' + $("#Text_Standard").html() );
        $("#Text_Deluxe").html('AI TTS <img width="14px" height="14px" src="/img/plus.png"> ' + $("#Text_Deluxe").html() );
        $("#Text_Premium").html('AI TTS <img width="14px" height="14px" src="/img/plus.png"> ' + $("#Text_Premium").html() );
        isChangeServiceText = 1;
    }
    QuotationSection_ONOFF("block");
    $("#PurchaseSection").css('display', "block");
}

/********************** Quotation *************************************/
function Save_Text() {
    TAreaID = document.getElementById("SrcTextArea");
    var SArray=new Array();
    var array = TAreaID.value.split("\n");
    var TextLen=0;
    for (i=0,j=0; i<array.length; i++) {
        buf = trim(array[i]);
        if (buf.length < 1) continue;
        TextLen += buf.length;
        SArray[j] = buf; j++;
    }
    if ( SArray.length < 1 ){
        alert("번역할 내용이 없습니다.");
        return false;
    }
    var SNDList = {};
    SNDList.SrcLang = $("#SrcLang option:selected").val();
    SNDList.TgtLang = $("#TgtLang option:selected").val();
    SNDList.TextLen = TextLen;
    SNDList.Text    = SArray;
    LockScreen();
    $.post("/processing/text_proc_save.do", SNDList, function(result) {
        UnLockScreen();
        if (result.isOK == 0) {
            alert("에러가 발생하였습니다.\n" + result.RText);
        } else {
            CalcCost(); // quotation.js : TTS 문장 저장 후 > 계산
        } 
    });
}

/***********************************************************
    Event
***********************************************************/
/******************** Clear Text ***************************************/
$("#TextClear").on('click', function(e) {
    e.preventDefault();
    e.stopPropagation();
    
    QuotationSection_ONOFF("none");
    $("#PurchaseSection").css('display', "none");
    $("#ReqDetail").css("display", "none");

    $("#SrcTextArea").val("");
    $('#text_cnt').text("0/"+TextMaxLen);
});

/******************** Delete Job ***************************************/
$('#txttsTransList').on('click', 'button', function (e) {
    if ( $(this).is("[Del_PrjName]") ) {
        Selected_Type_Clear();
        Trans_Type = 0;
        Trans_Layout = 0;
        Trans_QAPremium = 0;
        Trans_Urgent = 0;
    
        var SNDList = {};
        SNDList.projectname = $(this).attr("Del_PrjName");
        LockScreen();
        $.post("/processing/tts_proc_delete.do", SNDList, function(result) {
            UnLockScreen();
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            }
            $("#SrcTextArea").val("");
            $('#text_cnt').text("0/"+TextMaxLen);
            Status = 0;
            UpdateDocTranTable();
        });
    }
});

/******************** Check Text Length ***************************************/
$("#SrcTextArea").on('keyup', function() {
    $('#text_cnt').text($(this).val().length+"/"+TextMaxLen);

    if ( UserCheck != "isOn" ) return;

    if($(this).val().length > TextMaxLen) {
        $(this).val($(this).val().substring(0, TextMaxLen));
        $('#text_cnt').text(TextMaxLen+"/"+TextMaxLen);
        alert(TextMaxLen+"자를 초과하였습니다.");
    }

    if ( Trans_Type > 0 ) {
        Trans_Type = 0;
        Trans_Layout = 0;
        Trans_QAPremium = 0;
        Trans_Urgent = 0;
        Selected_Type_Clear();
    }

    Quotation_Section_Open();
});

<?
if ( isset( $_SESSION['useridkey'] ) ) {
    include "sub_cost_inc/quotation.js";
    include "sub_cost_inc/purchase.js";
}
?>

$("#PS_FileText").text("텍스트 입력");

if ( UserCheck == "isOn" )
    GetCode();
