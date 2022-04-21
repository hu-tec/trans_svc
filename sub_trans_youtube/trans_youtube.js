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
    var BizType = 5; // Youtube

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
        $('#YouTubeList').DataTable( {
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
                
                Table = $('#YouTubeList').DataTable();
                TotRecCnt = Table.data().count();
                if ( TotRecCnt == 0 ) {
                    $("#SrcLang").val("-");
                    $("#TgtLang").val("-");
                    $("#PS_1").addClass('active'); 
                    QuotationSection_ONOFF("none");
                    $("#PurchaseSection").css('display', "none");
                    $("#DIV_YouTubeList").css("display", "none");
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

                    if ( Trans_Type == 1 ) {
                        Set_Add_Option(0, 0);
                        Selected_Type_Switch( document.getElementById("BTNType_Basic") );
                    }
                    else if ( Trans_Type == 2 ) {
                        Set_Add_Option(0, 1);
                        Selected_Type_Switch( document.getElementById("BTNType_STandard") );
                    }
                    else if ( Trans_Type == 3 || Trans_Type == 4 ) {
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
                    setTimeout(function() { UpdateDocTranTable(); }, 5000);
                }
                // else {
                //     UnLockScreen();
                // }

                $("#DIV_YouTubeList").css("display", "");
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
    $('#YouTubeList').on('click', 'button', function (e) {
        if ( $(this).is("[Del_PrjName]") &&  $(this).is("[Del_FName]") ) {
            DeleteFile (0, $(this).attr("Del_PrjName"), $(this).attr("Del_FName") );
        }
    });

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

    /******************** Check Source/Target Language ***************************************/
    function Check_Lang() {
        if ( $("#SrcLang option:selected").val() == '-' ){
            alert("[원문 언어]를 선택하여 주십시오.");
            return false;
        }

        // if ( $("#TgtLang option:selected").val() == '-' ){
        //     alert("[번역할 언어]를 선택하여 주십시오.");
        //     return false;
        // }
        if ( $("#SrcLang option:selected").val() == $("#TgtLang option:selected").val() ){
            alert("[원문 언어]와 [번역할 언어]가 동일합니다. 다시 선택하여 주십시오.");
            return false;
        }

        return true;
    }
    function getUrlParams(URL) {     
        var params = {};  
        URL.replace(/[?&]+([^=&]+)=([^&]*)/gi, 
            function(str, key, value) { 
                params[key] = value; 
            }
        );        
        return params; 
    }
    function Unix_timestamp(t){
        var date = new Date(t*1000);
        var year = date.getFullYear();
        var month = "0" + (date.getMonth()+1);
        var day = "0" + date.getDate();
        var hour = "0" + date.getHours();
        var minute = "0" + date.getMinutes();
        var second = "0" + date.getSeconds();
        return year + "-" + month.substr(-2) + "-" + day.substr(-2) + " " + hour.substr(-2) + ":" + minute.substr(-2) + ":" + second.substr(-2);
    }
    /******************** Save Info ************************************/
    function Save_Info(SrcLang, TgtLang, Title, Time, OURL, DURL) {
        var SNDList = {};
        SNDList.SrcLang = SrcLang;
        SNDList.TgtLang = TgtLang;
        SNDList.ori_fname = Title;
        SNDList.duration = Time;
        SNDList.ori_URL = OURL;
        SNDList.down_URL = DURL;
        LockScreen();
        $.post("/processing/youtube_proc_save_info.do", SNDList, function(result) {
            UnLockScreen();
            if (result.isOK == 0) {
                alert(result.RText);
            } else {
                setTimeout(function() { UpdateDocTranTable(); }, 10);
            } 
        });
    }
    /******************** Button Click ************************************/
    $("#BTN_YouTube").on('click', function(e){
        if ( TotRecCnt > 0 ) {
            alert("진행 중인 건이 있습니다.\r\n결제하시거나 삭제 후 진행 바랍니다.");
            return false;
        }

        if (  !Check_Lang() ) return;
        YURL = $("#Youtube_URL").val();
        isExist = YURL.toLowerCase().indexOf("www.youtube.com/watch?v=");
        if ( YURL.toLowerCase().indexOf("www.youtube.com/watch?v=") < 0 ) {
            alert("유튜브의 링크를 확인하여 주시기 바랍니다.\n예 : https://www.youtube.com/watch?v=abcdedg");
            return;
        }
        if ( YURL.toLowerCase().indexOf("https://") < 0 )  YURL = "https://" + YURL;

        var SNDList = {};
        SNDList.SrcLang = $("#SrcLang option:selected").val();
        SNDList.TgtLang = $("#TgtLang option:selected").val();
        SNDList.YouTubeURL = YURL;
        LockScreen();
        $.post("/processing/youtube_proc_get_html.do", SNDList, function(result) {
            UnLockScreen();
            if (result.isOK == -1) {
                alert(result.RText);
            }
            else if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            } else {
                Video_Title = result.Video_Title;
                Video_Time = result.Video_Time;
                Video_URL = result.Video_URL;
                Video_Size = result.Video_Size;

                URLParms = getUrlParams(Video_URL);
                RTime = ConvertTime(Video_Time);

                // alert( Video_Title+"\r\n Time:"+Video_Time+"\r\n"+Video_URL+"\r\n FSize:"+Video_Size+"\r\n");
                // alert( Unix_timestamp(URLParms.expire) );

                MSG = "다음과 같이 유튜브 영상을 확인하였습니다.\r\n\r\n";
                MSG += "(제목) " + Video_Title + "\r\n";
                MSG += "(영상시간) " + RTime + "\r\n\r\n";
                MSG += "진행하시겠습니까?";
                if ( confirm(MSG) == true ) {
                    Save_Info($("#SrcLang option:selected").val(), $("#TgtLang option:selected").val(), Video_Title, Video_Time, YURL, Video_URL);
                }
            } 
        });
    });

    /********************  Open Quotation ***************************************/
    function Quotation_Section_Open() {
        $('#BTNType_Basic').css("display", "block");
        $("#BTN_File_Layout").css("display", "none");

        if ( isChangeServiceText == 0 ) { 
            $("#Text_Basic").html( "AI YouTube to Text" );
            $("#Text_Basic").siblings('div .showPopup').html("<p>유튜브 영상을 텍스트로 변경하는 서비스입니다.</p>");

            $("#Text_Standard").html('AI YouTube to Text <img width="14px" height="14px" src="/img/plus.png"> 휴먼감수');
            $("#Text_Standard").siblings('div .showPopup').html("<p>텍스트파일로 변경한 결과물을 휴먼감수로 정확도를 높입니다.</p>");

            $("#Text_Deluxe").html('AI YouTube to Text <img width="14px" height="14px" src="/img/plus.png"> 휴먼감수 <img width="14px" height="14px" src="/img/plus.png"><br>AI 번역');
            $("#Text_Deluxe").siblings('div .showPopup').html("<p>휴먼감수까지 마친 텍스트 파일을 109개 언어으로 AI번역을 합니다.</p>");

            $("#Text_Premium").html('AI YouTube to Text <img width="14px" height="14px" src="/img/plus.png"> 휴먼감수 <img width="14px" height="14px" src="/img/plus.png"><br>AI 번역 <img width="14px" height="14px" src="/img/plus.png"> 휴먼번역감수' );
            $("#Text_Premium").siblings('div .showPopup').html("<p>Deluxe에서 번역된 최종 번역물을 휴먼이 번역감수를 합니다.</p>");

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

$("#PS_FileText").text("URL 입력");

if ( UserCheck == "isOn" ) {
    GetCode();
}
