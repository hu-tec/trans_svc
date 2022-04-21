    var ExList;
    var SelectedMenu=1;

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
    function AddSelect(SEL, TXT, VAL, exid) {
        ELOpt = document.createElement('option');
        //ELOpt.class = "div2";
        ELOpt.value = VAL;
        ELOpt.text  = TXT;
        if ( VAL == exid ) $(ELOpt).attr("selected",true);
        
        SEL.appendChild(ELOpt);
        return SEL;
    }
    /****************************************************/
    var RcvStatus=0;
    var RcvSvcType=0;
    function UpdateTranReqTable() {
        var SNDList = {};
        SNDList.SelectedMenu = SelectedMenu;
        LockScreen();
        var Table = $('#TransWorkList').DataTable( {
            "ajax": {
                "type" : "POST",
                "url" : "/processing/man_proc_req_list.do",
                "data" : SNDList,
                "dataType": "JSON"
            },
            "autoWidth": false,
            "destroy": true,
            "pageLength": 10,
            "lengthMenu": [10, 20, 50, 100],
            "language": {
                "infoEmpty": "No data available in table"
            },
            "columns": [
                { "data": "seq" }, // 0 
                { "data": "svctype" }, // 1
                { "data": "sdate" }, // 2
                { "data": "projectname" }, // 3
                { "data": "jobname" }, // 4
                { "data": "lang" }, // 5
                { "data": "ori_fname" }, // 6
                { "data": "count" }, // 7
                { "data": "prediction_time" }, // 8
                { "data": "trans_type" }, // 9
                null, // 10
                { "data": "layout" }, // 11
                { "data": "urgent" }, // 12
                { "data": "qa_premium" }, // 13
                { "data": "expert_category" }, // 14
                { "data": "status" }, // 15
                { "data": "jobid" }, // 16
                null, // 17
                { "data": "exist_file_1" }, // 18
                { "data": "exist_file_2" }, // 19
            ],
            'columnDefs': [
                {'targets': 0, 'className': 'dt-body-center', 'searchable': false}, // seq
                {'targets': 1, 'className': 'dt-body-center',  // svctype
                    'render': function (data, type, full, meta) {
                        return BizCase(full.svctype);
                    }
                },
                {'targets': 2, 'className': 'dt-body-center', // sdate
                    'render': function (data, type, full, meta) { 
                        RcvStatus = parseInt(full.status);
                        RcvSvcType = parseInt(full.svctype);
                        LPath = full.projectname;
                        LLink = "";

                        if ( SelectedMenu == 1 ) {
                            if ( RcvSvcType == 0 ) { // DOC
                                LPath = full.jobid;
                                LLink = "https://cloud.memsource.com/web/job/"+LPath+"/translate";
                            }
                            else if ( RcvSvcType == 1 ) { // TTS
                                LLink = "/post_editor/?b=1&t=t&p="+LPath;
                            }
                            else if ( 2<= RcvSvcType && RcvSvcType <= 5 ) { // STT, Video, S2S, Youtube
                                if ( parseInt(full.trans_type) == 2 )
                                    LLink = "/post_editor/?b="+RcvSvcType+"&t=c&p="+LPath;
                                else
                                    LLink = "/post_editor/?b="+RcvSvcType+"&t=t&p="+LPath;
                            }
                            //SET = "<a href="+LLink+" style='text-decoration:underline' target='"+LPath+"'>";
                            //SET += full.sdate + "</a>";
                            SET = full.sdate.substr(0, 10) +" <a href="+LLink+" class='btn btn-primary btn-sm' role='button' aria-disabled='true' target='"+LPath+"'>";
                            SET += "Editor</a>";

                            if ( RcvSvcType == 0 ) { // DOC
                                SET += "<br> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
                                SET += "<a id='DOC_CREATE' href='javascript://' class='btn btn-success btn-sm' role='button' aria-disabled='true'";
                                SET += " Project='"+full.projectname+"' JobName='"+full.jobname+"' JobId='"+full.jobid+"'";
                                SET += ">번역 파일 생성</a>";
                            }
                        }
                        else SET = full.sdate;
                        return SET;
                    } 
                },
                {'targets': 3, 'className': 'dt-body-center', 'visible': false }, // projectname
                {'targets': 4, 'className': 'dt-body-center', 'visible': false }, // jobname
                {'targets': 5, 'className': 'dt-body-center' }, // lang
                {'targets': 6, 'className': 'dt-body-center', // ori_fname
                    'render': function (data, type, full, meta) { 
                        SET = "-";
                        ORI_FileName = "";
                        if ( RcvSvcType != 1 ) {
                            if ( RcvSvcType == 5 ) // Youtube
                                ORI_FileName = full.ori_fname.substr(0, 12);
                            else {
                                EPos = full.ori_fname.lastIndexOf( "." );
                                if ( EPos > 8 )
                                    ORI_FileName = full.ori_fname.substr(0, 8)+"..."+full.ori_fname.substr(EPos, full.ori_fname.length-EPos);
                                else ORI_FileName = full.ori_fname;
                            }
                        }

                        if ( SelectedMenu == 1 ) {
                            if ( RcvSvcType == 0 ) { // DOC
                                SET = ORI_FileName + "<br>";
                                // SET += "<a href='javascript://' id='Ori_FileDown' Down_TName='"+full.jobname+"' Down_OName='"+full.ori_fname+"'>원본 다운로드</a><br>";
                                if ( parseInt(full.exist_file_1) == 1 )
                                    SET += "<a class='file-upload-button' href='javascript://' id='FileDown' Down_TName='"+full.jobname+"' Down_OName='"+full.ori_fname+"'>번역 작업파일 받기</a>";
                                // SET = "<div id='FileDown' style='text-decoration:underline;cursor: pointer;'";
                                // SET += "Down_TName='"+full.jobname+"' Down_OName='"+full.ori_fname+"'>문서 다운로드</div>";
                            }
                        }
                        else {
                            if ( RcvSvcType == 0 ) {
                                SET = ORI_FileName;
                            }
                            // else if ( RcvSvcType == 1 ) SET = "TTS";
                            // else if ( RcvSvcType == 2 ) SET = "STT";
                            // else if ( RcvSvcType == 3 ) SET = "영상";
                        }
                        return SET;
                    } 
                },
                {'targets': 7, 'className': 'dt-body-center', 'searchable': false, // count
                    'render': function (data, type, full, meta) {
                        if ( RcvSvcType == 0 ) 
                            SET = AddComma(full.count) + " Word";
                        else if ( RcvSvcType == 1 ) 
                            SET = AddComma(full.count) + " Char";
                        else if ( 2<= RcvSvcType && RcvSvcType <= 3) 
                            SET = ConvertTime (full.count);
                        return SET;
                    }
                },
                {'targets': 8, 'className': 'dt-body-center', // prediction_time
                    'render': function (data, type, full, meta) {
                        return Display_Time("", full.prediction_time, 1);
                    }
                }, 
                {'targets': 9, 'className': 'dt-body-center', // trans_type
                    'render': function (data, type, full, meta) {
                        return ServiceType(full.svctype, full.trans_type);
                    }
                },
                {'targets': 10, 'className': 'dt-body-center', 
                    'render': function (data, type, full, meta) { // 휴먼작업 유형
                        return ServiceOption(full.urgent, full.qa_premium, full.expert_category, full.layout);
                    }
                },
                {'targets': 11, 'className': 'dt-body-center', 'visible': false }, // layout
                {'targets': 12, 'className': 'dt-body-center', 'visible': false }, // urgent
                {'targets': 13, 'className': 'dt-body-center', 'visible': false }, // qa_premium
                {'targets': 14, 'className': 'dt-body-center', 'visible': false }, // expert_category
                {'targets': 15, 'className': 'dt-body-center', 'visible': false }, // status
                {'targets': 16, 'className': 'dt-body-center', 'visible': false }, // jobid
                {'targets': 17, 'className': 'dt-body-center', 
                    'render': function (data, type, full, meta) { 
                        if ( SelectedMenu == 1 ) {
                            if ( RcvSvcType == 0 ) {
                                ELINPUT="";
                                //if ( parseInt(full.layout) == 1 ) {
                                    ELINPUT = '<label class="file-upload-button" for="input-file">최종 파일 업로드</label>';
                                    ELINPUT += '<input type="file" name="input-file" id="input-file" style="display:none"';
                                    ELINPUT += ' Project="'+full.projectname+'"';
                                    ELINPUT += ' JobName="'+full.jobname+'"';
                                    ELINPUT += ' JobId="'+full.jobid+'"';
                                    ELINPUT += '><br>';
                                //}

                                ELSEL = document.createElement("select");
                                ELSEL.setAttribute("Project", full.projectname);
                                ELSEL.setAttribute("JobName", full.jobname);
                                ELSEL.setAttribute("JobId", full.jobid);

                                ELSEL = AddSelect(ELSEL, "작업중", "51", 0);
                                ELSEL = AddSelect(ELSEL, "작업 완료", "52", 0);
                                return ELINPUT + ELSEL.outerHTML;
                            } else return "";
                        } else {
                            ret = StatusAttr(RcvSvcType, RcvStatus);
                            return "<font class='"+ret.color+"'>"+ret.text+"</font>";
                        }
                    }
                },
                {'targets': 18, 'className': 'dt-body-center', 'visible': false }, // exist_file_1
                {'targets': 19, 'className': 'dt-body-center', 'visible': false }, // exist_file_2
            ],
            "initComplete": function(settings, json){
                UnLockScreen();
                if ( SelectedMenu == 1 ) {
                    $("#HEAD_EDIT").html('<font color="blue">편집</font>');
                    $("#HEAD_TYPE").html('<font color="blue">다운로드</font>');
                }
                else if ( SelectedMenu == 2 ) {
                    $("#HEAD_EDIT").text("주문 요청일");
                    $("#HEAD_TYPE").text("문서명");
                }
            }
        } );
    }
    /***********************************************************/
    $("#subMenu_1, #subMenu_2").on('click',function (e) {
        e.preventDefault();
        $("#subMenu li a").removeClass("active");
        $(this).toggleClass("active");

        SelectedMenu = this.id.substr(8,1);
        UpdateTranReqTable();
    });

    var DNCheck;
    var Tmp_Name="";
    var Ori_Name="";
    function DownLookCheck() { 
        if ( parseInt($.cookie('FDownOk'))==1 ) {
            $.cookie('FDownOk', 0, { path: '/' });
            clearTimeout(DNCheck);
            FileDownload(Tmp_Name, Ori_Name, 1);
        }
        else {
            DNCheck = setTimeout(function() { DownLookCheck(); }, 1000);
        }
        return false;
    }
    /***********************************************************/
    $('#TransWorkList').on('click', 'a', function (e) {
        if ( $(this).attr("id") == "FileDown" ) {
            Tmp_Name = $(this).attr("Down_TName");
            Ori_Name = $(this).attr("Down_OName");

            $.cookie('FDownOk', 0, { path: '/' });
            FileDownload(Tmp_Name, Ori_Name, 0);
            DownLookCheck();
        }
        else if ( $(this).attr("id") == "DOC_CREATE" ) {
            var SNDList = {};
            SNDList.Project = $(this).attr("Project");
            SNDList.JobName = $(this).attr("JobName");
            SNDList.JobId = $(this).attr("JobId");
            LockScreen();
            $.post("/processing/expert_doc_file_create.do", SNDList, function(result) {
                UnLockScreen();
                if (result.isOK == 0) {
                    alert("에러가 발생하였습니다.\n" + result.RText);
                }
                else {
                    alert("번역 결과 파일을 생성했습니다.");
                    setTimeout(function() { UpdateTranReqTable(); }, 10);
                }
            });
        }
    });

    // file selected
    $('#TransWorkList').on('change', '#input-file', function (e) {
        var formData = new FormData();
        formData.append("JobName", $(this).attr("JobName"));
        formData.append('upfile[]', this.files[0]);

        LockScreen();
        $.ajax({
            url: "/processing/expert_doc_result_upload.do",
            data: formData,
            type: 'POST',
            enctype: 'multipart/form-data',
            processData: false,
            contentType: false,
            dataType: 'json',
            cache: false,
            success: function(result) {
                if (result.isOK == 0) {
                    alert("파일 저장 중 에러가 발생하였습니다.\n" + result.RText);
                } else {
                    alert("결과 파일을 저장했습니다.")
                }
                UnLockScreen();
            },
            error: function(XMLHttpRequest, errorMsg, errorThrown) {
                console.log(errorThrown+" : "+errorMsg);
                UnLockScreen();
            }
        });
        $("#input-file").val("");
    });

    /****************** Select Status : 52 - Complete **********************************/
    $('#TransWorkList').on('change', 'select', function (e) {
        //if ( $("option:selected", this).val() != '-' ) {
            var SNDList = {};
            SNDList.Project = $(this).attr("Project");
            SNDList.JobName = $(this).attr("JobName");
            SNDList.JobId = $(this).attr("JobId");
            SNDList.status = $("option:selected", this).val();
            LockScreen();
            $.post("/processing/expert_doc_set_status.do", SNDList, function(result) {
                UnLockScreen();
                if (result.isOK == 0) {
                    alert("에러가 발생하였습니다.\n" + result.RText);
                }
                else {
                    alert("저장되었습니다.");
                    UpdateTranReqTable();
                }
            });
        //}
    });

    if ( UserCheck == "isOn" ) {
        UpdateTranReqTable();
    }
