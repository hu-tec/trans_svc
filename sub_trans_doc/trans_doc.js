var Status=0;
var Trans_Type=0;
var Trans_Layout    = 0;
var Trans_QAPremium = 0;
var Trans_Urgent    = 0;

var TotalCost=0;
var PredictionTime=0;

var isCalculation=0;

var TotRecCnt=0;

var BizType = 0; // DOC

/******************** Lock / UnLock ***************************************/
function LockScreen() {
    document.querySelector(".d-flex").classList.add("active");
    document.querySelector(".loading").classList.add("active");
}
function UnLockScreen() {
    document.querySelector(".d-flex").classList.remove("active");
    document.querySelector(".loading").classList.remove("active");
}

/****************** Delete selected File **********************************/
function DeleteFile (isAll, PRJName, JName )  {
    Selected_Type_Clear();
    Trans_Type = 0;
    Trans_Layout = 0;
    Trans_QAPremium = 0;
    Trans_Urgent = 0;

    var SNDList = {};
    SNDList.isAll       = isAll;
    SNDList.projectname = PRJName;
    if ( isAll == 0 )
        SNDList.tmp_fname = JName;

    LockScreen();
    $.post("/processing/doc_proc_file_delete.do", SNDList, function(result) {
        UnLockScreen();
        if (result.isOK == 0) {
            alert("에러가 발생하였습니다.\n" + result.RText);
        }
        Status = 0;
        UpdateDocTranTable();
    });
}

/********************** Analysis *************************************/
var ANAProject="";
function AnalysisFile( ) {
    var SNDList = {};
    SNDList.projectname     = ANAProject;
    SNDList.Trans_Type      = Trans_Type;
    SNDList.Trans_Layout    = Trans_Layout;
    SNDList.Trans_QAPremium = Trans_QAPremium;
    SNDList.Trans_Urgent    = Trans_Urgent;

    LockScreen();
    $.post("/processing/doc_proc_analysis.do", SNDList, function(result) {
        UnLockScreen();
        if (result.isOK == 0) {
            alert("에러가 발생하였습니다.\n" + result.RText);
        }
        else {
            //UpdateDocTranTable();
        }
    });
}

/****************************************************/
function Alert_Message () {
    alert("파일 분석을 진행합니다.\n파일 크기와 개수에 따라 분석 시간이 오래 걸릴 수 있습니다.\n분석에 완료시까지 기다려 주시기 바랍니다.\n");
}

function UpdateDocTranTable() {
    var SNDList = {};
    LockScreen();
    $('#DocTransList').DataTable( {
        "ajax": {
            "type" : "POST",
            "url" : "/processing/doc_proc_file_list.do",
            "data" : SNDList,
            "dataType": "JSON"
        },
        "autoWidth": false,
        "destroy": true,
        "pageLength": 10,
        //"lengthMenu": [10, 20, 50, 100],
        "fixedHeader" : true,
        "bLengthChange": true,
        "bPaginate": false,
        "bFilter": false,
        "ordering": false,
        'paging': false, 
        "info": false,
        "columns": [
            { "data": "seq" }, // 0 SEQ
            { "data": "projectname" }, // 1
            { "data": "projectid" }, // 2
            { "data": "srcLang" }, // 3
            { "data": "tgtLang" }, // 4
            { "data": "jobid" }, // 5
            { "data": "ori_fname" }, // 6
            { "data": "tmp_fname" }, // 7
            { "data": "numofchar" }, // 8
            { "data": "numofword" }, // 9
            { "data": "numoftu" }, // 10
            { "data": "cost" }, // 11
            { "data": "status" }, //12
            null, // 13 Progress
            { "data": "trans_type" }, // 14
            { "data": "layout" }, // 15
            { "data": "trans_quality" }, // 16
            { "data": "urgent" }, // 17
            { "data": "prediction_time" }, // 18
            { "data": "expert_category" }, // 19
            { "data": "exist_file_1" }, // 20
            { "data": "sdate" }, // 21
        ],
        'columnDefs': [
            {'targets': 0, 'className': 'dt-body-center' }, // seq
            {'targets': 1, 'className': 'dt-body-center', 'visible': false }, // projectname
            {'targets': 2, 'className': 'dt-body-center', 'visible': false }, // projectid
            {'targets': 3, 'className': 'dt-body-center', 'visible': false,
                'render': function (data, type, full, meta){
                    $("#SrcLang").val(full.srcLang);
                    $("#TgtLang").val(full.tgtLang);
                    SET = $("#SrcLang option:selected").text() + ">" + $("#TgtLang option:selected").text();
                    return SET;
                }
            }, // 언어
            {'targets': 4, 'className': 'dt-body-center', 'visible': false }, // 대상 언어
            {'targets': 5, 'className': 'dt-body-center', 'visible': false }, // jobid
            {'targets': 6, 'className': 'dt-body-left' }, // ori_fname
            {'targets': 7, 'className': 'dt-body-left', 'visible': false }, // tmp_fname
            {'targets': 8, 'className': 'dt-body-center', // numofchar
                'render': function (data, type, full, meta) {
                    return AddComma(full.numofchar);
                }
            },
            {'targets': 9, 'className': 'dt-body-center', // numofword
                'render': function (data, type, full, meta) {
                    return AddComma(full.numofword);
                }
            },
            {'targets': 10, 'className': 'dt-body-center', 'visible': false, // numoftu
                'render': function (data, type, full, meta) {
                    return AddComma(full.numoftu);
                }
            },
            {'targets': 11, 'className': 'dt-body-center', // Cost
                'render': function (data, type, full, meta) {
                    return Display_Cost("", full.cost, 1);
                }
            },
            {'targets': 12, 'className': 'dt-body-center', 
                'render': function (data, type, full, meta) { 
                    ret = StatusAttr(0, parseInt(full.status));
                    return "<font class='"+ret.color+"'>"+ret.text+"</font>";
                }
            },
            {'targets': 13, 'className': 'dt-body-center', 
                'render': function (data, type, full, meta) { // 진행 선택
                    Status = parseInt(full.status);
                    SET = "";
                    if ( /* Status == 0 || */ Status == 2 )
                        SET = '<button type="button" class="btn-s btn-purple" Del_PrjName="'+full.projectname+'" Del_FName="'+full.tmp_fname+'">문서삭제</button>';
                    return SET;
                }
            },
            {'targets': 14, 'className': 'dt-body-center', 'visible': false }, // trans_type
            {'targets': 15, 'className': 'dt-body-center', 'visible': false }, // layout
            {'targets': 16, 'className': 'dt-body-center', 'visible': false }, // trans_quality
            {'targets': 17, 'className': 'dt-body-center', 'visible': false }, // urgent
            {'targets': 18, 'className': 'dt-body-center', 'visible': false }, // prediction_time
            {'targets': 19, 'className': 'dt-body-center', 'visible': false }, // expert_category
            {'targets': 20, 'className': 'dt-body-center', 'visible': false }, // exist_file_1
            {'targets': 21, 'className': 'dt-body-center', 'visible': false }, // sdate
        ],
        "initComplete": function(settings, json){
            UnLockScreen();

            $(".circleOnOff").removeClass('active');

            Table = $('#DocTransList').DataTable();
            TotRecCnt = Table.rows().data().length;
            if ( Table.data().count() == 0 ) {
                $("#SrcLang").val("-");
                $("#TgtLang").val("-");
                $("#PS_1").addClass('active');
                QuotationSection_ONOFF("none");
                $("#PurchaseSection").css('display', "none");
                $("#DIV_DOCList").css("display", "none");
                return;
            }
            
            numofchar = 0;
            numofword = 0;
            TotalCost = 0;
            PredictionTime = 0;

            Trans_Type      = parseInt( Table.cell( 0, 14 ).data() );
            Trans_Layout    = parseInt( Table.cell( 0, 15 ).data() );
            Trans_QAPremium = parseInt( Table.cell( 0, 16 ).data() );
            Trans_Urgent    = parseInt( Table.cell( 0, 17 ).data() );

            Upload_Count = 0;
            Status = 2; // 분석 완료
            for (i=0; i<TotRecCnt; i++) {
                RecStatus = parseInt(Table.cell( i, 12 ).data());
                if ( RecStatus == 0 ) Upload_Count ++;
                if ( RecStatus != 2 ) Status = 1; // 분석중
                
                numofchar += parseInt(Table.cell( i, 8 ).data());
                numofword += parseInt(Table.cell( i, 9 ).data());
                TotalCost += parseInt(Table.cell( i, 11 ).data());
                PredictionTime += parseInt(Table.cell( i, 18 ).data());
            }

            ////// Progress Step /////////////
            if ( Status < 2 ) $("#PS_2").addClass('active');
            else if ( Status == 2 ) {
                if ( Trans_Type == 0 ) $("#PS_3").addClass('active');
                else $("#PS_4").addClass('active');
            }
            ///////////////////////////////////

            if ( Status != 2 && Upload_Count == TotRecCnt ) {
                setTimeout(function() { Alert_Message(); }, 100);
                ANAProject = Table.cell( 0, 1 ).data();
                setTimeout(function() { AnalysisFile() }, 10);
                //AnalysisFile( Table.cell( 0, 1 ).data() );
            }
            
            if ( Status == 2 ) { // 분석 완료
                if ( Trans_QAPremium==0 || Table.cell(0, 19).data().length < 1 ) ExCategory = '-';
                else ExCategory = Table.cell(0, 19).data();
                $("#Select_Premium").val(ExCategory).prop("selected", true);

                /*if ( Trans_Type == 1 ) {
                    Set_Add_Option(0, 0);
                    Selected_Type_Switch( document.getElementById("BTNType_Basic") );
                }
                else*/
                if ( Trans_Type == 2 ) {
                    Set_Add_Option(0, 0);
                    Selected_Type_Switch( document.getElementById("BTNType_STandard") );
                }
                else if ( Trans_Type == 3 || Trans_Type == 4 ) {
                    Set_Add_Option(1, 1);
                    if ( Trans_Type == 3 ) Selected_Type_Switch( document.getElementById("BTNType_Deluxe") );
                    else Selected_Type_Switch( document.getElementById("BTNType_Premium") );
                }

                if ( Trans_Layout == 1 )    Add_Selected_Switch( document.getElementById("BTN_File_Layout"), 0 ); 
                if ( Trans_QAPremium == 1 ) Add_Selected_Switch( document.getElementById("BTN_Quality_Premium"), 0 ); 
                if ( Trans_Urgent == 1 )    Add_Selected_Switch( document.getElementById("BTN_Urgent"), 0 );

                QuotationSection_ONOFF("block");
                $("#PurchaseSection").css('display', "block");
            }
            else if ( Status <= 1 ) { // 분석 중
                setTimeout(function() { UpdateDocTranTable(); }, 3000);
            }
            // else {
            //     UnLockScreen();
            // }

            $("#DIV_DOCList").css("display", "");
        }
    } );
}
/***********************************************************/
function AddOpt(id, ListData) {
    ELSEL = document.getElementById(id);

    for(var i in ListData) {
        if ( ListData[i].code == 'at') continue;
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

            setTimeout(function() { GetExpertCode(); }, 10);
        } 
    });
}
/***********************************************************/
/***********************************************************/
/***********************************************************/
/******************** Check Text Length ***************************************/
$("#Lang_Change").on('click', function() {
    CS = $("#SrcLang option:selected").val();
    CT = $("#TgtLang option:selected").val();
    $("#SrcLang").val( CT );
    if ( CS != 'at') $("#TgtLang").val( CS );
    else $("#TgtLang").val( '-' );
});

/***** 파일 업로드 ******/
// preventing page from redirecting
$("html").on("dragover", function(e) {
    e.preventDefault();
    e.stopPropagation();
});

$("html").on("drop", function(e) { e.preventDefault(); e.stopPropagation(); });

// Drag enter
$('#uploadfile').on('dragenter', function (e) {
    e.stopPropagation();
    e.preventDefault();
});

// Drag over
$('#uploadfile').on('dragover', function (e) {
    e.stopPropagation();
    e.preventDefault();
});

// Drop
$('#uploadfile').on('drop', function (e) {
    e.stopPropagation();
    e.preventDefault();
    var files = e.originalEvent.dataTransfer.files;
    if (files != null) {
        if (files.length < 1) {
            alert("폴더 업로드 불가");
            return;
        } else {
            if ( GetFileInfo(files) ) File_Upload();
        }
    } else {
        alert("ERROR");
    }
});

// Open file selector on div click
$("#uploadfile").click(function(){
    $("#input-file").trigger("click");
});

// file selected
$("#input-file").bind("change", function(e){
    if ( GetFileInfo(this.files) ) File_Upload();
});

$('#DocTransList').on('click', 'button', function (e) {
    if ( $(this).is("[Del_PrjName]") &&  $(this).is("[Del_FName]") ) {
        DeleteFile (0, $(this).attr("Del_PrjName"), $(this).attr("Del_FName") );
    }
});

/* 파일 처리 */
var fileIndex = 0;
var totalFileSize = 0; // 등록할 전체 파일 사이즈
var fileList = new Array(); // 파일 리스트
var fileSizeList = new Array(); // 파일 사이즈 리스트
var uploadSize = 50; // 등록 가능한 파일 사이즈 MB
var maxUploadSize = 500; // 등록 가능한 총 파일 사이즈 MB
/******************* Get File Information ***********************/
function GetFileInfo( inputFiles ) {
    if ( UserCheck != "isOn" ) {
        alert("로그인하신 후 이용 바랍니다.")
        return false;
    }

    if ( TotRecCnt > 0 ) {
        alert("진행 중인 건이 있습니다.\r\n결제하시거나 삭제 후 진행 바랍니다.");
        return false;
    }

    if ( $("#SrcLang option:selected").val() == '-' ){
        alert("[원문 언어]와 [번역할 언어]를 선택하여 주십시오.");
        return false;
    }
    if ( $("#TgtLang option:selected").val() == '-' ){
        alert("[번역할 언어]를 선택하여 주십시오.");
        return false;
    }
    if ( $("#SrcLang option:selected").val() == $("#TgtLang option:selected").val() ){
        alert("[원문 언어]와 [번역할 언어]가 동일합니다. 다시 선택하여 주십시오.");
        return false;
    }

    if (!inputFiles) {
        alert("업로드 대상파일이 없습니다.");
        return false;
    }

    if ( inputFiles.length > 10 ) {
        alert("10개 파일까지 업로드 가능합니다.");
        return false;
    }

    for (var i = 0; i < inputFiles.length; i++) {
        var fileName = inputFiles[i].name;
        var fileNameArr = fileName.split("\.");
        var ext = fileNameArr[fileNameArr.length - 1];

        var fileSize = inputFiles[i].size;
        if (fileSize <= 0) {
            alert("0kb file return");
            return false;
        }

        var fileSizeKb = fileSize / 1024; // 파일 사이즈(단위 :kb)
        var fileSizeMb = fileSizeKb / 1024; // 파일 사이즈(단위 :Mb)

        var fileSizeStr = "";
        if ((1024 * 1024) <= fileSize) fileSizeStr = fileSizeMb.toFixed(2) + " Mb"; // 파일 용량이 1메가 이상인 경우 
        else if ((1024) <= fileSize)   fileSizeStr = parseInt(fileSizeKb) + " kb";
        else                           fileSizeStr = parseInt(fileSize) + " byte";

        if ($.inArray(ext, ['doc', 'docx', 'ppt', 'pptx', 'txt', 'xls', 'xlsx']) < 0) {
            alert("번역이 불가능한 파일 입니다. " + fileName);
            return false;
        } else if (fileSizeMb > uploadSize) { // 파일 사이즈 체크
            alert("용량 초과\n업로드 가능 용량 : " + uploadSize + " MB");
            return false;
        } else {
            totalFileSize += fileSizeMb; // 전체 파일 사이즈
            fileList[ fileIndex ] = inputFiles[i]; // 파일 배열에 넣기
            fileSizeList[ fileIndex ] = fileSizeMb; // 파일 사이즈 배열에 넣기
            fileIndex++;
        }
    }

    if (totalFileSize > maxUploadSize) { // 용량을 500MB를 넘을 경우 업로드 불가
        alert("총 용량 초과\n총 업로드 가능 용량 : " + maxUploadSize + " MB"); // 파일 사이즈 초과 경고창
        return false;
    }

    return true;
}

/******************* FILE Upload  ***********************/
function File_Upload(){
    Table = $('#DocTransList').DataTable();
    if ( Table.rows().data().length > 0) {
        Table.clear();
        Table.draw();
    }

    var uploadFileList = Object.keys(fileList);

    var formData = new FormData();
    formData.append("srcLang", $("#SrcLang option:selected").val());
    formData.append("tgtLang", $("#TgtLang option:selected").val());

    for (var i = 0; i < uploadFileList.length; i++) {
        formData.append('upfile[]', fileList[ uploadFileList[i] ]);
    }
    LockScreen();
    $.ajax({
        url: "/processing/doc_proc_fileup_db.do",
        data: formData,
        type: 'POST',
        enctype: 'multipart/form-data',
        processData: false,
        contentType: false,
        dataType: 'json',
        cache: false,
        success: function(result) {
            UnLockScreen();
            if (result.isOK == 0) {
                alert("번역도중 에러가 발생하였습니다.\n" + result.RText);
            } else {
                Status = 0;
                setTimeout(function() { UpdateDocTranTable(); }, 10);
            }
        },
        error: function(XMLHttpRequest, errorMsg, errorThrown) {
            console.log(errorThrown+" : "+errorMsg);
        }
    });

    $("#input-file").val("");
    
    totalFileSize = 0; // 등록할 전체 파일 사이즈
    fileList = new Array(); // 파일 리스트
    fileSizeList = new Array(); // 파일 사이즈 리스트
}
    
<?
if ( isset( $_SESSION['useridkey'] ) ) {
include "sub_cost_inc/quotation.js";
include "sub_cost_inc/purchase.js";
}
?>

if ( UserCheck == "isOn" ) {
    GetCode();
}
