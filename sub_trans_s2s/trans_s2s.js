    var Status=0;

    var Trans_Type=0;
    var Trans_Layout    = 0;
    var Trans_QAPremium = 0;
    var Trans_Urgent    = 0;

    var TotalCost=0;
    var PredictionTime=0;

    var PointChargeAmount=0;
    var isCalculation=0;

    var isTrans = 0;
    var BizType = 4; // S2S

    var isChangeServiceText = 0;

    var TotRecCnt=0;

    /* 파일 처리 */
    var fileIndex = 0;
    var totalFileSize = 0; // 등록할 전체 파일 사이즈
    var fileList = new Array(); // 파일 리스트
    var fileSizeList = new Array(); // 파일 사이즈 리스트
    var uploadSize = 50; // 등록 가능한 파일 사이즈 MB
    var maxUploadSize = 500; // 등록 가능한 총 파일 사이즈 MB

    /******************** Lock / UnLock ***************************************/
    function LockScreen() {
        document.querySelector(".d-flex").classList.add("active");
        document.querySelector(".loading").classList.add("active");
    }
    function UnLockScreen() {
        document.querySelector(".d-flex").classList.remove("active");
        document.querySelector(".loading").classList.remove("active");
    }
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
            alert("오디오 파일의 [언어]를 선택하여 주십시오.");
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

        // if ( inputFiles.length > 10 ) {
        //     alert("10개 파일까지 업로드 가능합니다.");
        //     return false;
        // }

        for (var i = 0; i < inputFiles.length; i++) {
            //var fileName = inputFiles[i].name;
            //var fileNameArr = fileName.split("\.");
            //var ext = fileNameArr[fileNameArr.length - 1];

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

            /*if ($.inArray(ext, ['doc', 'docx', 'ppt', 'pptx', 'txt', 'xls', 'xlsx']) < 0) {
                alert("번역이 불가능한 파일 입니다. " + fileName);
                return false;
            } else if (fileSizeMb > uploadSize) { // 파일 사이즈 체크
                alert("용량 초과\n업로드 가능 용량 : " + uploadSize + " MB");
                return false;
            } else*/ {
                totalFileSize += fileSizeMb; // 전체 파일 사이즈
                fileList[ fileIndex ] = inputFiles[i]; // 파일 배열에 넣기
                fileSizeList[ fileIndex ] = fileSizeMb; // 파일 사이즈 배열에 넣기
                fileIndex++;
            }
        }

        // if (totalFileSize > maxUploadSize) { // 용량을 500MB를 넘을 경우 업로드 불가
        //     alert("총 용량 초과\n총 업로드 가능 용량 : " + maxUploadSize + " MB"); // 파일 사이즈 초과 경고창
        //     return false;
        // }

        return true;
    }

    /****************************************************/
    var FirstAlert=0;
    function Alert_Message ( STS ) {
        if ( STS < 2 ) { 
            if ( FirstAlert==0 )
                alert("파일 분석을 진행합니다.\n파일 크기에 따라 분석 시간이 오래 걸릴 수 있습니다.\n분석에 완료시까지 기다려 주시기 바랍니다.\n");
            FirstAlert = 1;
        }
    }

    function UpdateDocTranTable() {
        var SNDList = {};
        SNDList.BizType = BizType;
        LockScreen();
        $('#S2SList').DataTable( {
            "ajax": {
                "type" : "POST",
                "url" : "/processing/speech_proc_list.do",
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
                { "data": "sdate" }, // 1
                { "data": "projectname" }, // 2
                { "data": "job_name" }, // 3
                { "data": "ori_fname" }, // 4
                { "data": "srcLang" }, // 5
                { "data": "tgtLang" }, // 6
                { "data": "duration" }, // 7
                { "data": "cost" }, // 8
                { "data": "status" }, // 9
                { "data": "trans_type" }, // 10
                { "data": "qa_premium" }, // 11
                { "data": "urgent" }, // 12
                { "data": "expert_category" }, // 13
                { "data": "prediction_time" }, // 14
                { "data": "exist_file" }, // 15
                null,
            ],
            'columnDefs': [
                {'targets': 0, 'className': 'dt-body-center', 'visible': false }, // seq
                {'targets': 1, 'className': 'dt-body-center', 'visible': false }, // sdate
                {'targets': 2, 'className': 'dt-body-center', 'visible': false }, // projectname
                {'targets': 3, 'className': 'dt-body-center', 'visible': false }, // job_name
                {'targets': 4, 'className': 'dt-body-center', // ori_fname
                    'render': function (data, type, full, meta){
                        SET="";
                        EPos = full.ori_fname.lastIndexOf( "." );
                        if ( EPos > 30 )
                            SET += full.ori_fname.substr(0, 30)+"..."+full.ori_fname.substr(EPos, full.ori_fname.length-EPos);
                        else SET += full.ori_fname;
                        return SET;
                    }
                },
                {'targets': 5, 'className': 'dt-body-center', // srcLang
                    'render': function (data, type, full, meta){
                        $("#SrcLang").val(full.srcLang);
                        $("#TgtLang").val(full.tgtLang);
                        if ( full.tgtLang == '-' )
                            SET = $("#SrcLang option:selected").text();
                        else {
                            isTrans = 1;
                            SET = $("#SrcLang option:selected").text() + ">" + $("#TgtLang option:selected").text();
                        }
                        $("#TgtLang option[value='"+full.srcLang+"']").remove();
                        return SET;
                    }
                }, 
                {'targets': 6, 'className': 'dt-body-center', 'visible': false }, // tgtLang
                {'targets': 7, 'className': 'dt-body-center', // duration
                    'render': function (data, type, full, meta){
                        SET = ConvertTime (full.duration);
                        $("#AudioTime").text(SET);
                        return SET;
                    }
                },
                {'targets': 8, 'className': 'dt-body-center', // cost
                    'render': function (data, type, full, meta) {
                        TotalCost = full.cost;
                        return Display_Cost("", full.cost, 1);
                    }
                },
                {'targets': 9, 'className': 'dt-body-center', // status
                    'render': function (data, type, full, meta) { 
                        Status = parseInt(full.status);
                        ret = StatusAttr(2, Status);
                        return "<font class='"+ret.color+"'>"+ret.text+"</font>";
                    }
                }, 
                {'targets': 10, 'className': 'dt-body-center', 'visible': false }, // trans_type
                {'targets': 11, 'className': 'dt-body-center', 'visible': false }, // qa_premium
                {'targets': 12, 'className': 'dt-body-center', 'visible': false }, // urgent
                {'targets': 13, 'className': 'dt-body-center', 'visible': false }, // expert_category
                {'targets': 14, 'className': 'dt-body-center', 'visible': false, // prediction_time
                    'render': function (data, type, full, meta) {
                        return full.prediction_time;
                    }
                },
                {'targets': 15, 'className': 'dt-body-center', 'visible': false }, // exist_file
                {'targets': 16, 'className': 'dt-body-center', // 선택
                    'render': function (data, type, full, meta) {
                        SET = "";
                        if ( Status == 2 ) {
                            SET = '<button type="button" class="btn-s btn-purple" Del_PrjName="'+full.projectname+'" Del_FName="'+full.job_name+'">삭제</button>';
                        }
                        return SET;
                    }
                },
            ],
            "initComplete": function(settings, json){
                UnLockScreen(); 
                $(".circleOnOff").removeClass('active');
                
                Table = $('#S2SList').DataTable();
                TotRecCnt = Table.data().count();
                if ( TotRecCnt == 0 ) {
                    $("#SrcLang").val("-");
                    $("#TgtLang").val("-");
                    $("#PS_1").addClass('active');
                    QuotationSection_ONOFF("none");
                    $("#PurchaseSection").css('display', "none");
                    $("#DIV_S2SList").css("display", "none");
                    return;
                }

                ////// Progress Step /////////////
                if ( Status < 2 ) $("#PS_2").addClass('active');
                else if ( Status == 2 ) {
                    if ( Trans_Type == 0 ) $("#PS_3").addClass('active');
                    else $("#PS_4").addClass('active');
                }

                ///////////////////////////////////                
                if ( Status == 2 ) { // 분석 완료
                    if ( Table.cell(0, 13).data().length < 1 ) ExCategory = '-';
                    else ExCategory = Table.cell(0, 13).data();
                    $("#Select_Premium").val(ExCategory).prop("selected", true);

                    Trans_Type = Table.cell(0, 10).data();
                    Trans_QAPremium = parseInt( Table.cell( 0, 11 ).data() );
                    Trans_Urgent    = parseInt( Table.cell( 0, 12 ).data() );

                    /*if ( Trans_Type == 1 ) {
                        Set_Add_Option(0, 0);
                        Selected_Type_Switch( document.getElementById("BTNType_Basic") );
                    }
                    else if ( Trans_Type == 2 ) {
                        Set_Add_Option(0, 1);
                        Selected_Type_Switch( document.getElementById("BTNType_STandard") );
                    }
                    else */ if ( Trans_Type == 3 || Trans_Type == 4 ) {
                        Set_Add_Option(1, 1);
                        if ( Trans_Type == 3 ) Selected_Type_Switch( document.getElementById("BTNType_Deluxe") );
                        else Selected_Type_Switch( document.getElementById("BTNType_Premium") );
                    }

                    if ( Trans_QAPremium == 1 ) Add_Selected_Switch( document.getElementById("BTN_Quality_Premium"), 0 ); 
                    if ( Trans_Urgent == 1 )    Add_Selected_Switch( document.getElementById("BTN_Urgent"), 0 );
                    Quotation_Section_Open();
                }
                else if ( Status <= 1 ) { // 분석 중
                    setTimeout(function() { Alert_Message(Status); }, 10);
                    setTimeout(function() { UpdateDocTranTable(); }, 1000);
                }
                // else {
                //     UnLockScreen();
                // }

                $("#DIV_S2SList").css("display", "");
            }
        } );
    }

    /****************** Delete selected File **********************************/
    function DeleteFile (isAll, PRJName, JName )  {
        $("#QuotationLock").css('display', "none");
        $("#PurchaseSection").css('display', "none");
        $("#QuotationSection").css('display', "none");
        Selected_Type_Clear();
        Trans_Type = 0;
        Trans_Layout = 0;
        Trans_QAPremium = 0;
        Trans_Urgent = 0;

        var SNDList = {};
        SNDList.BizType = BizType;
        SNDList.projectname = PRJName;
        SNDList.job_name = JName;
        LockScreen(); 
        $.post("/processing/speech_proc_file_delete.do", SNDList, function(result) {
            UnLockScreen(); 
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            }
            else {
                Status = -1;
                setTimeout(function() { UpdateDocTranTable(); }, 10);
            }
        });
    }
    /******************* FILE Delete ***********************/
    $('#S2SList').on('click', 'button', function (e) {
        if ( $(this).is("[Del_PrjName]") &&  $(this).is("[Del_FName]") ) {
            DeleteFile (0, $(this).attr("Del_PrjName"), $(this).attr("Del_FName") );
        }
    });

    /******************* FILE Upload  ***********************/
    function File_Upload(){
        Table = $('#S2SList').DataTable();
        if ( Table.rows().data().length > 0) {
            Table.clear();
            Table.draw();
        }

        var uploadFileList = Object.keys(fileList);

        var formData = new FormData();
        formData.append("BizType", BizType);
        formData.append("srcLang", $("#SrcLang option:selected").val());
        formData.append("TgtLang", $("#TgtLang option:selected").val());
        for (var i = 0; i < uploadFileList.length; i++) {
            formData.append('upfile[]', fileList[ uploadFileList[i] ]);
        }
        LockScreen();
        $.ajax({
            url: "/processing/speech_proc_fileup_db.do",
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
                    setTimeout(function() { UpdateDocTranTable(); }, 10);
                }
            },
            error: function(XMLHttpRequest, errorMsg, errorThrown) {
                console.log(errorThrown+" : "+errorMsg);
                UnLockScreen();
            }
        });

        $("#input-file").val("");
        
        totalFileSize = 0; // 등록할 전체 파일 사이즈
        fileList = new Array(); // 파일 리스트
        fileSizeList = new Array(); // 파일 사이즈 리스트
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

                if ( UserCheck == "isOn" )
                    setTimeout(function() { GetExpertCode(); }, 10);
            } 
        });
    }

    /****************************************************/
    /****************************************************/
    /****************************************************/
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
            } 
            else if (files.length > 1) {
                alert("1개의 파일만 업로드 가능합니다.");
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

    /******************** Change Target Lang ************************************/
    $("#TgtLang").on('change', function(e){
        if ( Status > 2 ) {
            return;
        }
        if ( TotRecCnt > 0 ) {
            var SNDList = {};
            SNDList.BizType = BizType;
            SNDList.projectname = Table.cell( 0, 2 ).data();
            SNDList.TgtLang = $(this).val();
            LockScreen();
            $.post("/processing/speech_proc_lang_set.do", SNDList, function(result) {
                UnLockScreen();
                if (result.isOK == 0) {
                    alert("에러가 발생하였습니다.\n" + result.RText);
                } else { 
                    setTimeout(function() { UpdateDocTranTable(); }, 10);
                } 
            });
        }
    });

    /********************  Open Quotation ***************************************/
    function Quotation_Section_Open() {
        //$('#BTNType_Basic').css("display", "none");
        // $('#BTNType_STandard').css("display", "none");
        $('#BTNType_STandard').attr('style', 'display:none !important');
        $("#BTN_File_Layout").css("display", "none");

        if ( isChangeServiceText == 0 ) { 
            $("#Text_Deluxe").html('AI STT <img width="14px" height="14px" src="/img/plus.png"> 휴먼감수 <img width="14px" height="14px" src="/img/plus.png"><br>AI 번역 <img width="14px" height="14px" src="/img/plus.png"> AI TTS');
            $("#Text_Deluxe").siblings('div .showPopup').html("<p>휴먼감수까지 마친 텍스트 파일을 109개 언어로 AI번역하고 AI TTS로 음성파일을 생성합니다.</p>");

            $("#Text_Premium").html('AI STT <img width="14px" height="14px" src="/img/plus.png"> 휴먼감수 <img width="14px" height="14px" src="/img/plus.png"><br>AI 번역 <img width="14px" height="14px" src="/img/plus.png"> 휴먼번역감수  <img width="14px" height="14px" src="/img/plus.png"> AI TTS' );
            $("#Text_Premium").siblings('div .showPopup').html("<p>Deluxe에서 번역된 최종 번역물을 휴먼이 번역감수한 후 AI TTS로 음성파일을 생성합니다.</p>");

            $("#BTN_Urgent > div > h6").html("긴급");
            $("#BTN_Urgent > div > p").html("긴급으로 작업을 요청하실 경우 선택 (30% 추가)");
            isChangeServiceText = 1;
        }
    
        QuotationSection_ONOFF("block");
        $("#PurchaseSection").css('display', "block");
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
