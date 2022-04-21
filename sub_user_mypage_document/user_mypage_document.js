/******************** Lock / UnLock ***************************************/
function LockScreen() {
    document.querySelector(".d-flex").classList.add("active");
    document.querySelector(".loading").classList.add("active");
}
function UnLockScreen() {
    document.querySelector(".d-flex").classList.remove("active");
    document.querySelector(".loading").classList.remove("active");
}
    
<?include "sub_user/user_mypage_menu.js"; ?>
/****************************************************/
function Get_Sum() {
    var SNDList = {};
    $.post("/processing/user_proc_sum.do", SNDList, function(result) {
        if (result.isOK == 0) {
            alert("에러가 발생하였습니다.\n" + result.RText);
        } 
        if (result.isOK == 1) {
            $('#TotalCount').text(result.TotalCount);
            $('#CompleteCount').text(result.CompleteCount);
            $('#OngoingCount').text(result.OngoingCount);

            setTimeout(function() { GetUserRequestList(); }, 10);
        } 
    });
}
/****************************************************/
var RcvStatus=0;
var BizType=0;
function GetUserRequestList() {
    var SNDList = {};

    SNDList.isAll = 0;
    if ( $("#svctype option:selected").val() == '-' )
        SNDList.isAll = 1;
    else
        SNDList.svctype = $("#svctype option:selected").val();

    if ( $("#Status option:selected").val() != '-' )
        SNDList.Status = $("#Status option:selected").val();

    if ( $("#SVCOption option:selected").val() != '-' ) {
        SVCOption = $("#SVCOption option:selected").val();
        if ( SVCOption == 'Urgent' ) SNDList.Check_Urgent = 1;
        else if ( SVCOption == 'QPremium' ) SNDList.Check_QPremium = 1;
        else if ( SVCOption == 'Layout' ) SNDList.Check_Layout = 1;
    }

    if ( $('#StartDate').val().length > 0 ) SNDList.StartDate = $('#StartDate').val();
    if ( $('#EndDate').val().length > 0 ) SNDList.EndDate = $('#EndDate').val();

    $('#UserRequestList').DataTable( {
        "ajax": {
            "type" : "POST",
            "url" : "/processing/user_proc_reqlist.do",
            "data" : SNDList,
            "dataType": "JSON"
        },
        "autoWidth": false,
        "destroy": true,
        "pageLength": 10,
        "lengthMenu": [10, 20, 50, 100],
        "fixedHeader" : true,
        "bLengthChange": true,
        "bPaginate": true,
        "bFilter": true,
        "ordering": true,
        'paging': true, 
        "info": true,
        "columns": [
            { "data": "seq" }, // 0 SEQ
            { "data": "svctype" }, // 1
            { "data": "projectname" }, // 2
            { "data": "sdate" }, // 3
            { "data": "lang" }, // 4
            { "data": "fname1" }, // 5
            { "data": "fname2" }, // 6
            null, // 7
            { "data": "size" }, // 8
            { "data": "prediction_time" }, // 9
            { "data": "cost" }, // 10
            { "data": "status" }, // 11
            { "data": "trans_type" }, // 12
            { "data": "layout" }, // 13
            { "data": "qa_premium" }, // 14
            { "data": "urgent" }, // 15
            { "data": "expert_category" }, // 16
            null, // 17
            null, // 18
            { "data": "exist_file_1" }, // 19
            { "data": "exist_file_2" }, // 20
        ],
        'columnDefs': [
            {'targets': 0, 'className': 'dt-body-center' }, // seq
            {'targets': 1, 'className': 'dt-body-center', // svctype
                'render': function (data, type, full, meta) {
                    return BizCase(full.svctype);
                }
            },
            {'targets': 2, 'className': 'dt-body-center', 'visible': false }, // projectname
            {'targets': 3, 'className': 'dt-body-center',}, // sdate
            {'targets': 4, 'className': 'dt-body-center' }, // lang
            {'targets': 5, 'className': 'dt-body-center', 'visible': false }, // fname1 (tmp_fname, src_audio)
            {'targets': 6, 'className': 'dt-body-center', 'visible': false }, // fname2 (ori_fname, tgt_audio)
            {'targets': 7, 'className': 'dt-body-center' , 
                'render': function (data, type, full, meta) {
                    RcvStatus = parseInt(full.status);
                    BizType = parseInt(full.svctype);
                    
                    SET = "";
                    ORI_FileName = "";
                    if ( BizType != 1 ) {
                        if ( BizType == 5 ) // Youtube
                            ORI_FileName = full.fname2.substr(0, 12);
                        else {
                            EPos = full.fname2.lastIndexOf( "." );
                            if ( EPos > 8 )
                                ORI_FileName = full.fname2.substr(0, 8)+"..."+full.fname2.substr(EPos, full.fname2.length-EPos);
                            else ORI_FileName = full.fname2;
                        }
                    }
                    
                    if ( BizType == 0 ) { // DOC
                        SET = ORI_FileName;
                    }
                    else if ( BizType == 1 && RcvStatus == 100 ) { // TTS
                        AUDIO="";
                        if ( full.fname1.length > 0 && parseInt(full.exist_file_1) == 1)
                            AUDIO = "<audio controls src='/file_download/"+full.fname1+".mp3'></audio>";
                        if ( full.fname2.length > 0 && parseInt(full.exist_file_2) == 1)
                            AUDIO += "<br><audio controls src='/file_download/"+full.fname2+".mp3'></audio>";
                        SET = AUDIO;
                    }
                    else if ( 2 <= BizType && BizType <= 5 ) { // (Souece Audio) STT, VIDEO, S2S, Youtube
                        SET = ORI_FileName;
                        SET += '<br>';
                        if ( full.fname1.length > 0 && parseInt(full.exist_file_1) == 1)
                            SET += "<audio controls src='/file_upload/"+full.fname1+".mp3' style='height:40px'></audio>";
                    }
                    
                    return SET;
                }
            }, 
            {'targets': 8, 'className': 'dt-body-center', // size
                'render': function (data, type, full, meta) {
                    if ( BizType == 0 ) 
                        SET = AddComma(full.size) + " Word";
                    else if ( BizType == 1 ) 
                        SET = AddComma(full.size) + " Char";
                    else if ( 2 <= BizType && BizType <= 5 ) // TIME : STT, VIDEO, S2S, Youtube
                        SET = ConvertTime (full.size);
                    return SET;
                }
            },
            {'targets': 9, 'className': 'dt-body-center', // prediction_time
                'render': function (data, type, full, meta) {
                    return Display_Time("", full.prediction_time, 1);
                }
            },
            {'targets': 10, 'className': 'dt-body-center', // cost
                'render': function (data, type, full, meta) {
                    return Display_Cost("", full.cost, 1);
                }
            },
            {'targets': 11, 'className': 'dt-body-center', // status
                'render': function (data, type, full, meta) { 
                    ret = StatusAttr(BizType, RcvStatus);
                    return "<font class='"+ret.color+"'>"+ret.text+"</font>";
                }
            },
            {'targets': 12, 'className': 'dt-body-center',  // trans_type
                'render': function (data, type, full, meta) { 
                    return ServiceType(full.svctype, full.trans_type);
                }
            },
            {'targets': 13, 'className': 'dt-body-center', 'visible': false }, // layout
            {'targets': 14, 'className': 'dt-body-center', 'visible': false }, // trans_quality
            {'targets': 15, 'className': 'dt-body-center', 'visible': false }, // urgent
            {'targets': 16, 'className': 'dt-body-center', 'visible': false }, // expert_category
            {'targets': 17, 'className': 'dt-body-center' , // 선택 사항
                'render': function (data, type, full, meta) { 
                    return ServiceOption(full.urgent, full.qa_premium, full.expert_category, full.layout);
                }
            }, 
            {'targets': 18, 'className': 'dt-body-center' , 
                'render': function (data, type, full, meta) {
                    SET = "";
                    if ( RcvStatus < 3 ) { // 결제 전 삭제 버튼
                        SET = '<button type="button" class="btn-s btn-red" SvcType='+BizType+' Del_PrjName="'+full.projectname+'" Del_FName="'+full.fname1+'">삭제</button>';
                    }
                    else {
                        if ( RcvStatus == 100 ) {
                            ADate = full.sdate.toString().replace(/:/g, '') + '_';
                            RcvTitle = BizCase(full.svctype) + '_' + ADate + full.lang.toString().replace('>', '-') + '_';
                            if ( BizType == 0 ) { // DOC
                                if ( parseInt(full.exist_file_1) == 1) {
                                    AName = RcvTitle + full.fname2;
                                    SET = '<button type="button" class="btn-s btn-green" Down_TName="'+full.fname1+'" Down_OName="'+AName+'">문서 받기</button>';
                                }
                            }
                            else if ( BizType == 1 ) { // TTS
                                if ( full.fname1.length > 0 && parseInt(full.exist_file_1) == 1) {
                                    AName = RcvTitle + "원문.mp3";
                                    SET = '<button type="button" class="btn-s btn-blue"';
                                    if ( full.fname2.length > 0 && parseInt(full.exist_file_2) == 1) SET += ' style="font-size:0.8rem"';
                                    SET += ' Down_TName="'+full.fname1+'.mp3" Down_OName="'+AName+'">원문-음성</button>';
                                }
                                if ( full.fname2.length > 0 && parseInt(full.exist_file_2) == 1) {
                                    AName = RcvTitle + "번역.mp3";
                                    SET += '<br><button type="button" class="btn-s btn-blue" style="padding:0.3rem;font-size:0.8rem;" Down_TName="'+full.fname2+'.mp3" Down_OName="'+AName+'">번역-음성</button>';
                                }
                            }
                            else if ( 2<= BizType && BizType <= 5 ) { // STT, Video, S2S, Youtube
                                if ( BizType == 4 ) { // S2S
                                    if ( full.fname1.length > 0 && parseInt(full.exist_file_2) == 1) {
                                        AName = RcvTitle + full.fname2 + ".mp3";
                                        SET += '<br><button type="button" class="btn-s btn-blue" Down_TName="'+full.fname1+'.mp3" Down_OName="'+AName+'">번역 음성</button>';
                                    }
                                }
                                else if ( parseInt(full.exist_file_1) == 1) {
                                    AName = RcvTitle  + full.fname2;
                                    SET = '<button type="button" class="btn-s btn-green" SvcType='+BizType+' PRJ="'+full.projectname+'" TType='+full.trans_type+' Down_AudioName="'+full.fname1+'" Down_OName="'+AName+'">문서 받기</button>';
                                }
                            }
                        }
                    }
                    return SET;
                }
            },
            {'targets': 19, 'className': 'dt-body-center', 'visible': false }, // exist_file_1
            {'targets': 20, 'className': 'dt-body-center', 'visible': false }, // exist_file_2
        ],
        "initComplete": function(settings, json){
        }
    } );
}

/****************** Delete selected File **********************************/
function Delete_Proc (SVCType, PRJName, JName )  {
    var ProcName="";
    var SNDList = {};
    SNDList.BizType     = SVCType;
    SNDList.projectname = PRJName;
    SNDList.job_name    = JName;
    SNDList.isAll       = 0;

    if ( SVCType == 0 ) ProcName="doc_proc_file_delete";
    else if ( SVCType == 1 ) ProcName="tts_proc_delete";
    else if ( 2<= SVCType && SVCType <= 5 ) ProcName="speech_proc_file_delete";

    $.post("/processing/"+ProcName+".do", SNDList, function(result) {
        if (result.isOK == 0) {
            alert("에러가 발생하였습니다.\n" + result.RText);
        }
        else {
            setTimeout(function() { Get_Sum(); }, 10);
        }
    });
}

/***********************************************************/
var DNCheck;
var Tmp_Name="";
var Ori_Name="";
function DownLookCheck() { 
    if ( parseInt($.cookie('FDownOk'))==1 ) {
        $.cookie('FDownOk', 0, { path: '/' });
        FileDownload(Tmp_Name, Ori_Name);
        setTimeout(function() { UnLockScreen(); }, 100);
        clearTimeout(DNCheck);
    }
    else {
        DNCheck = setTimeout(function() { DownLookCheck(); }, 1000);
    }
    return false;
}
/****************** Select Delete or Download **********************************/
$('#UserRequestList').on('click', 'button', function (e) {
    if ( $(this).is("[Del_PrjName]") &&  $(this).is("[Del_FName]") ) {
        Delete_Proc( parseInt( $(this).attr("SvcType") ), $(this).attr("Del_PrjName"), $(this).attr("Del_FName") );
    }
    
    if ( $(this).is("[Down_TName]") && $(this).is("[Down_OName]")  ) {
        LockScreen();
        FileDownload( $(this).attr("Down_TName"), $(this).attr("Down_OName") );
        setTimeout(function() { UnLockScreen(); }, 100);
    }

    if ( $(this).is("[Down_AudioName]") && $(this).is("[Down_OName]")  ) { // S2S 제외
        SVCType = parseInt( $(this).attr("SvcType") );

        JobName = $(this).attr("Down_AudioName");
        OriName = $(this).attr("Down_OName");

        PRJ = $(this).attr("PRJ");
        TType = parseInt( $(this).attr("TType") );

        var SNDList = {};
        SNDList.BizType = SVCType;
        SNDList.JobName = JobName;

        Link = "/processing/speech_proc_filesave.do";

        $.post(Link, SNDList, function(result) {
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            } else { 
                LockScreen();

                if ( TType==3 || TType==4 ) { // Deluxe, Premium
                    $.cookie('FDownOk', 0, { path: '/' });
                }
                FileDownload(JobName, OriName+"_원문.txt");

                if ( TType==3 || TType==4 ) { // Deluxe, Premium
                    Tmp_Name = PRJ;
                    Ori_Name = OriName+"_번역.txt";
                    DownLookCheck();
                }
                else setTimeout(function() { UnLockScreen(); }, 100);

                // if ( TType==3 || TType==4 ) { // Deluxe, Premium
                //     setTimeout(function() { FileDownload(PRJ, "번역문_"+OriName); }, 1000);
                // }
            } 
        });
    }
});

/****************** Search ALL **********************************/
$('#BTN_Search').on('click', function (e) {
    GetUserRequestList( );
});

if ( UserCheck == "isOn" ) {
    Get_Sum();
}