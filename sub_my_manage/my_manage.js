    var ExList;
    var SelectedMenu=1;
    /****************************************************/
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
    /****************** Select Expert **********************************/
    $('#TransRequetList').on('change', 'select', function (e) {
        var SNDList = {};
        SNDList.SVCType = $(this).attr("SVCType");
        SNDList.ProjectName = $(this).attr("PRJName");
        SNDList.JobName = $(this).attr("JobName");
        
        if ( SelectedMenu == 1 ) {
            if ( $("option:selected", this).val() != '-' ) {
                SNDList.JobName = $(this).attr("JobName");
                SNDList.expert = $("option:selected", this).val();
                LockScreen();
                $.post("/processing/man_proc_expert_set.do", SNDList, function(result) {
                    UnLockScreen();
                    if (result.isOK == 0) {
                        alert("에러가 발생하였습니다.\n" + result.RText);
                    }
                    else {
                        alert("저장 되었습니다.");
                        UpdateTranReqTable();
                    }
                });
            }
        }
        else if ( SelectedMenu == 2 ) {
            SNDList.JobId = $(this).attr("JobId");
            SNDList.status = $("option:selected", this).val();
            LockScreen();
            $.post("/processing/man_proc_set_status.do", SNDList, function(result) {
                UnLockScreen();
                if (result.isOK == 0) {
                    alert("에러가 발생하였습니다.\n" + result.RText);
                }
                else {
                    alert("저장 되었습니다.");
                    UpdateTranReqTable();
                }
            });
        }
    });

    /***********************************************************/
    var DNCheck;
    var Tmp_Name="";
    var Ori_Name="";
    function DownLookCheck() { 
        if ( parseInt($.cookie('FDownOk'))==1 ) {
            $.cookie('FDownOk', 0, { path: '/' });
            FileDownload(Tmp_Name, Ori_Name, 1);
            clearTimeout(DNCheck);
        }
        else {
            DNCheck = setTimeout(function() { DownLookCheck(); }, 1000);
        }
        return false;
    }
    /***********************************************************/
    $('#TransRequetList').on('click', 'div', function (e) {
        if ( $(this).attr("id") == "FileDown" ) {
            Tmp_Name = $(this).attr("Down_TName");
            Ori_Name = $(this).attr("Down_OName");

            $.cookie('FDownOk', 0, { path: '/' });
            FileDownload(Tmp_Name, Ori_Name, 0);
            DownLookCheck();
        }
    });

    /***********************************************************/
    $('#TransRequetList').on('click', 'a', function (e) {
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
    /***********************************************************/
    $('#TransRequetList').on('change', '#input-file', function (e) {
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
    /****************************************************/
    var RcvStatus=0;
    var RcvSvcType=0;
    function UpdateTranReqTable() {
        var SNDList = {};
        
        SNDList.SelectedMenu = SelectedMenu;

        if ( $('#SVC_Type option:selected').val() != '-' )
            SNDList.SVCType = $("#SVC_Type option:selected").val();

        if ( $("#Status option:selected").val() != '-' )
            SNDList.Status = $("#Status option:selected").val();

        if ( $("#SVCOption option:selected").val() != '-' ) {
            SVCOption = $("#SVCOption option:selected").val();
            if ( SVCOption == 'Urgent' ) SNDList.Check_Urgent = 1;
            else if ( SVCOption == 'QPremium' ) SNDList.Check_QPremium = 1;
            else if ( SVCOption == 'Layout' ) SNDList.Check_Layout = 1;
        }

        if ( $('#Expert option:selected').val() != '-' )
            SNDList.Expert = $('#Expert option:selected').val();
        
        if ( $('#StartDate').val().length > 0 ) SNDList.StartDate = $('#StartDate').val();
        if ( $('#EndDate').val().length > 0 ) SNDList.EndDate = $('#EndDate').val();

        LockScreen();
        $('#TransRequetList').DataTable( {
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
            "columns": [
                { "data": "seq" }, // 0 SEQ
                { "data": "svctype" }, // 1
                { "data": "user" }, // 2
                { "data": "sdate" }, // 3
                { "data": "projectname" }, // 4
                { "data": "jobname" }, // 5
                { "data": "lang" }, // 6
                { "data": "ori_fname" }, // 7
                { "data": "count" }, // 8
                { "data": "cost" }, // 9
                { "data": "prediction_time" }, // 10
                { "data": "trans_type" }, // 11
                null, // 12
                { "data": "layout" }, // 13
                { "data": "urgent" }, // 14
                { "data": "qa_premium" }, // 15
                { "data": "expert_category" }, // 16
                { "data": "expert_id" }, // 17
                null, // 18 Progress
                { "data": "status" }, // 19
                { "data": "jobid" }, // 20
                { "data": "exist_file_1" }, // 21
                { "data": "exist_file_2" }, // 22
            ],
            'columnDefs': [
                {'targets': 0, 'className': 'dt-body-center', 'searchable': false}, // seq
                {'targets': 1, 'className': 'dt-body-center',  // svctype
                    'render': function (data, type, full, meta) {
                        return BizCase(full.svctype);
                    }
                },
                {'targets': 2, 'className': 'dt-body-center' }, // user
                {'targets': 3, 'className': 'dt-body-right', // sdate
                    'render': function (data, type, full, meta) { 
                        RcvStatus = parseInt(full.status);
                        RcvSvcType = parseInt(full.svctype);
                        LPath = full.projectname;
                        LLink = "";

                        if ( SelectedMenu == 2 || SelectedMenu == 3 ) { // 최종승인, 전체 현황
                            if ( RcvSvcType == 0 ) { // DOC
                                LPath = full.jobid;
                                LLink = "https://cloud.memsource.com/web/job/"+LPath+"/translate";
                            }
                            else if ( RcvSvcType == 1 ) { // TTS
                                LLink = "/post_editor/?b=1&t=t&p="+LPath;
                            }
                            else if ( 2<= RcvSvcType && RcvSvcType <= 5 ) { // STT, Video, S2S, Youtube
                                if ( parseInt(full.trans_type) <= 2 )
                                    LLink = "/post_editor/?b="+RcvSvcType+"&t=c&p="+LPath;
                                else
                                    LLink = "/post_editor/?b="+RcvSvcType+"&t=t&p="+LPath;
                            }
                            // SET = "<a href="+LLink+" style='text-decoration:underline' target='"+LPath+"'>";
                            // SET += full.sdate + "</a>";
                            SET = full.sdate.substr(0, 10) +" <a href="+LLink+" class='btn btn-primary btn-sm' role='button' aria-disabled='true' target='"+LPath+"'>";
                            SET += "Editor</a>";

                            if ( RcvSvcType == 0 ) { // DOC
                                SET += "<br>";
                                SET += "<a id='DOC_CREATE' href='javascript://' class='btn btn-success btn-sm' role='button' aria-disabled='true'";
                                SET += " Project='"+full.projectname+"' JobName='"+full.jobname+"' JobId='"+full.jobid+"'";
                                SET += ">번역 파일 생성</a>";
                            }
                        }
                        else SET = full.sdate;
                        return SET;
                    }
                },
                {'targets': 4, 'className': 'dt-body-center', 'visible': false }, // projectname
                {'targets': 5, 'className': 'dt-body-center', 'visible': false }, // jobname
                {'targets': 6, 'className': 'dt-body-center' }, // lang
                {'targets': 7, 'className': 'dt-body-left',
                    'render': function (data, type, full, meta) { // ori_fname
                        SET = "";
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

                        if ( RcvSvcType == 0 ) { // DOC
                            SET = ORI_FileName;
                            if ( ( SelectedMenu == 2 || SelectedMenu == 3 ) && parseInt(full.exist_file_1) == 1 ) {
                                SET += "<br>";
                                SET += "<a class='file-upload-button' href='javascript://' id='FileDown' Down_TName='"+full.jobname+"' Down_OName='"+full.ori_fname+"'>번역 파일 받기</a>";
                                
                                // SET = "<div id='FileDown' style='text-decoration:underline;cursor: pointer;'";
                                // SET += "Down_TName='"+full.jobname+"' Down_OName='"+full.ori_fname+"'>";
                            }
                            // EPos = full.ori_fname.lastIndexOf( "." );
                            // if ( EPos > 8 )
                            //     SET += full.ori_fname.substr(0, 8)+"..."+full.ori_fname.substr(EPos, full.ori_fname.length-EPos);
                            // else SET += full.ori_fname;
                            if ( ( SelectedMenu == 2 || SelectedMenu == 3 ) && parseInt(full.exist_file_1) == 1 ) SET += "</div>";
                        }
                        else if ( RcvSvcType == 1 ) { // TTS
                            if ( SelectedMenu == 2 || SelectedMenu == 3 ) {
                                AUDIO="";
                                if ( full.jobname.length > 0 && parseInt(full.exist_file_1) == 1)
                                    AUDIO = "<audio controls src='/file_download/"+full.jobname+".mp3'></audio>";
                                if ( full.ori_fname.length > 0 && parseInt(full.exist_file_2) == 1)
                                    AUDIO += "<br><audio controls src='/file_download/"+full.ori_fname+".mp3'></audio>";
                                SET = AUDIO;
                            }
                        }
                        else if ( 2<= RcvSvcType && RcvSvcType <= 5 ) { // STT, Video, S2S, Youtube
                            SET = ORI_FileName;
                            if ( SelectedMenu == 2 || SelectedMenu == 3 ) {
                                SET += '<br>';
                                if ( full.jobname.length > 0 && parseInt(full.exist_file_1) == 1) {
                                    SET += "<audio controls src='/file_upload/"+full.jobname+".mp3' style='height:40px'></audio>";
                                }
                                if ( RcvSvcType == 4 ) { // S2S
                                    if ( full.jobname.length > 0 && parseInt(full.exist_file_2) == 1) {
                                        SET += "<br><audio controls src='/file_download/"+full.jobname+".mp3' style='height:40px'></audio>";
                                    }
                                }
                            }
                        }
                        return SET;
                    } 
                }, 
                {'targets': 8, 'className': 'dt-body-center', 'searchable': false, // count
                    'render': function (data, type, full, meta) {
                        if ( RcvSvcType == 0 ) 
                            SET = AddComma(full.count) + " Word";
                        else if ( RcvSvcType == 1 ) 
                            SET = AddComma(full.count) + " Char";
                        else if ( 2<= RcvSvcType && RcvSvcType <= 5 ) // STT, Video, S2S, Youtube
                            SET = ConvertTime (full.count);
                        return SET;
                    }
                },
                {'targets': 9, 'className': 'dt-body-center', // Cost
                    'render': function (data, type, full, meta) {
                        return Display_Cost("", full.cost, 1);
                    }
                },
                {'targets': 10, 'className': 'dt-body-center', // prediction_time
                    'render': function (data, type, full, meta) {
                        return Display_Time("", full.prediction_time, 1);
                    }
                }, 
                {'targets': 11, 'className': 'dt-body-center', // trans_type
                    'render': function (data, type, full, meta) {
                        return ServiceType(full.svctype, full.trans_type);
                    }
                },
                {'targets': 12, 'className': 'dt-body-center', 
                    'render': function (data, type, full, meta) { // 휴먼작업 유형
                        return ServiceOption(full.urgent, full.qa_premium, full.expert_category, full.layout);
                    }
                },
                {'targets': 13, 'className': 'dt-body-center', 'visible': false }, // layout
                {'targets': 14, 'className': 'dt-body-center', 'visible': false }, // urgent
                {'targets': 15, 'className': 'dt-body-center', 'visible': false }, // qa_premium
                {'targets': 16, 'className': 'dt-body-center', 'visible': false }, // expert_category
                {'targets': 17, 'className': 'dt-body-center', 'visible': false }, // expert_id
                {'targets': 18, 'className': 'dt-body-center',
                    'render': function (data, type, full, meta) { // 진행 선택
                        if ( SelectedMenu == 1 ) {
                            ELSEL = document.createElement("select");
                            //ELSEL.setAttribute("onchange", "SelectExpert('"+full.jobname+"', this)");
                            ELSEL.setAttribute("SVCType", full.svctype);
                            ELSEL.setAttribute("PRJName", full.projectname);
                            ELSEL.setAttribute("JobName", full.jobname);
                            ELSEL = AddSelect(ELSEL, "- 선택 -", "-", 0);
                            for(var i in ExList)
                                ELSEL = AddSelect(ELSEL, ExList[i].name, ExList[i].useridkey, full.expert_id);
                        }
                        else {
                            for(var i in ExList) {
                                ELSEL = document.createElement("p");
                                if ( full.expert_id == ExList[i].useridkey ) {
                                    TNode = document.createTextNode(ExList[i].name);
                                    ELSEL.appendChild(TNode);
                                    break;
                                }
                            }
                        }
                        return ELSEL.outerHTML;
                    }
                },
                {'targets': 19, 'className': 'dt-body-center',
                    'render': function (data, type, full, meta) { // status
                        ELINPUT="";
                        if ( SelectedMenu == 2 || SelectedMenu == 3 ) {
                            if ( RcvSvcType == 0 ) {
                                ELINPUT = '<label class="file-upload-button" for="input-file">결과 업로드</label>';
                                ELINPUT += '<input type="file" name="input-file" id="input-file" style="display:none"';
                                ELINPUT += ' Project="'+full.projectname+'"';
                                ELINPUT += ' JobName="'+full.jobname+'"';
                                ELINPUT += ' JobId="'+full.jobid+'"';
                                ELINPUT += '><br>';
                            }
                        }

                        if ( SelectedMenu == 2 ) {
                                ELSEL = document.createElement("select");
                                ELSEL.setAttribute("SVCType", full.svctype);
                                ELSEL.setAttribute("PRJName", full.projectname);
                                ELSEL.setAttribute("JobName", full.jobname);
                                ELSEL.setAttribute("JobId", full.jobid);

                                ELSEL = AddSelect(ELSEL, "작업 완료", "52", 0);
                                ELSEL = AddSelect(ELSEL, "최종 완료", "100", 0);
                                ELSEL = AddSelect(ELSEL, "재작업", "51", 0);
                                return ELINPUT + ELSEL.outerHTML;
                        }
                        else {
                            ret = StatusAttr(RcvSvcType, RcvStatus);
                            return ELINPUT + "<font class='"+ret.color+"'>"+ret.text+"</font>";
                        }
                    }
                },
                {'targets': 20, 'className': 'dt-body-center', 'visible': false }, // jobid
                {'targets': 21, 'className': 'dt-body-center', 'visible': false }, // exist_file_1
                {'targets': 22, 'className': 'dt-body-center', 'visible': false }, // exist_file_2
            ],
            "initComplete": function(settings, json){
                UnLockScreen();
                $('#TransRequetList').DataTable().columns.adjust().draw();

                if ( SelectedMenu == 1 )
                    $('#TransRequetList').DataTable().column(19).visible(false);
                else if ( SelectedMenu == 4 ) {
                    $('#TransRequetList').DataTable().column(2).visible(false);
                    $('#TransRequetList').DataTable().column(8).visible(false);
                    $('#TransRequetList').DataTable().column(18).visible(false);
                }
            }
        } );
    }

    /***********************************************************/
    /*                     User */
    /****************************************************/
    $('#UserList').on('click', 'div', function (e) {
        if ( $(this).attr("id") == "QuitMent") {
            alert( $(this).attr("Ment") );
        }
        else if ( $(this).attr("id") == "UserOn" ) {
            var SNDList = {};
            SNDList.Uidx  = $(this).attr("UIdx");
            SNDList.EMail = $(this).attr("EMail");
            LockScreen();
            $.post("/processing/man_proc_reset_user.do", SNDList, function(result) {
                UnLockScreen();
                if (result.isOK == 0) {
                    alert("에러가 발생하였습니다.\n" + result.RText);
                }
                else {
                    UserListTable();
                }
            });
        }
    });
    /****************************************************/
    function UserListTable() {
        var SNDList = {};
        if ( $('#ULIST_StartDate').val().length > 0 ) SNDList.StartDate = $('#ULIST_StartDate').val();
        if ( $('#ULIST_EndDate').val().length > 0 )   SNDList.EndDate = $('#ULIST_EndDate').val();
        if ( $('#ULIST_Type option:selected').val() != '-' ) SNDList.utype = $('#ULIST_Type option:selected').val();
        LockScreen();
        $('#UserList').DataTable( {
            "ajax": {
                "type" : "POST",
                "url" : "/processing/man_proc_user_list.do",
                "data" : SNDList,
                "dataType": "JSON"
            },
            "autoWidth": false,
            "destroy": true,
            "pageLength": 10,
            "lengthMenu": [10, 20, 50, 100],
            "columns": [                
                { "data": "seq" }, // 0 SEQ
                { "data": "sdate" }, // 1
                { "data": "useridkey" }, // 2
                { "data": "userid" }, // 3
                { "data": "name" }, // 4
                { "data": "phone" }, // 5
                { "data": "utype" }, // 6
                { "data": "grade" }, // 7
                { "data": "account_name" }, // 8
                { "data": "account_number" }, // 9
                { "data": "birthday_yy" }, // 10
                { "data": "birthday_mm" }, // 11
                { "data": "birthday_dd" }, // 12
                { "data": "quit_ment" }, // 13
                { "data": "flag" }, // 14
            ],
            'columnDefs': [
                {'targets': 0, 'className': 'dt-body-center', 'searchable': false}, // seq
                {'targets': 1, 'className': 'dt-body-center', // sdate
                    'render': function (data, type, full, meta) { 
                        return full.sdate.substr(0,10);
                    }
                },
                {'targets': 2, 'className': 'dt-body-center', 'visible': false }, // useridkey
                {'targets': 3, 'className': 'dt-body-left', // userid
                    'render': function (data, type, full, meta) { 
                        return full.userid;
                    }
                },
                {'targets': 4, 'className': 'dt-body-center', // name
                    'render': function (data, type, full, meta) { 
                        return full.name;
                    }
                },
                {'targets': 5, 'className': 'dt-body-center',  // phone
                    'render': function (data, type, full, meta) { 
                        return full.phone;
                    }
                },
                {'targets': 6, 'className': 'dt-body-center' }, // utype
                {'targets': 7, 'className': 'dt-body-center', 'visible': false }, // grade
                {'targets': 8, 'className': 'dt-body-center' }, // account_name
                {'targets': 9, 'className': 'dt-body-center' }, // account_number
                {'targets': 10, 'className': 'dt-body-center', // birthday_yy
                    'render': function (data, type, full, meta) { 
                        SET="";
                        if ( full.birthday_yy>0)
                            SET = full.birthday_yy+"-"+full.birthday_mm+"-"+full.birthday_dd;
                        return SET;
                    }
                },
                {'targets': 11, 'className': 'dt-body-center', 'visible': false }, // birthday_mm
                {'targets': 12, 'className': 'dt-body-center', 'visible': false }, // birthday_dd
                {'targets': 13, 'className': 'dt-body-center', // quit_ment
                    'render': function (data, type, full, meta) {
                        SET = "";
                        if ( parseInt(full.flag) == 1 ) {
                            Ment = full.quit_ment.replace(/'/g, '"');
                            SET = "<div id='QuitMent' style='text-decoration:underline;cursor: pointer;' Ment='"+Ment+"'>내용보기</div>";
                        }
                        return SET;
                    }
                },
                {'targets': 14, 'className': 'dt-body-center', // flag
                    'render': function (data, type, full, meta) {
                        if ( parseInt(full.flag) == 1 ) 
                            SET = "<div id='UserOn' style='text-decoration:underline;cursor: pointer;' UIdx='"+full.useridkey+"' EMail='"+full.userid+"'>복원</div>";
                        else
                            SET = "이용중";
                        return SET;
                    }
                },
            ],
            "initComplete": function(settings, json){
                UnLockScreen();
            }
        } );
    }
    /****************************************************/
    function PointOutListTable() {
        var SNDList = {};
        LockScreen();
        $('#PointOutList').DataTable( {
            "ajax": {
                "type" : "POST",
                "url" : "/processing/man_proc_pointout_list.do",
                "data" : SNDList,
                "dataType": "JSON"
            },
            "autoWidth": false,
            "destroy": true,
            "pageLength": 10,
            "lengthMenu": [10, 20, 50, 100],
            "columns": [                
                { "data": "seq" }, // 0 SEQ
                { "data": "sdate" }, // 1
                { "data": "useridkey" }, // 2
                { "data": "userid" }, // 3
                { "data": "name" }, // 4
                { "data": "birthday" }, // 5
                { "data": "phone" }, // 6
                { "data": "utype" }, // 7
                { "data": "account_name" }, // 8
                { "data": "account_number" }, // 9
                { "data": "amount" }, // 10
                { "data": "status" }, // 11
            ],
            'columnDefs': [
                {'targets': 0, 'className': 'dt-body-center', 'searchable': false}, // seq
                {'targets': 1, 'className': 'dt-body-center'}, // sdate
                {'targets': 2, 'className': 'dt-body-center', 'visible': false }, // useridkey
                {'targets': 3, 'className': 'dt-body-left'}, // userid
                {'targets': 4, 'className': 'dt-body-center'}, // name
                {'targets': 5, 'className': 'dt-body-center'}, // birthday
                {'targets': 6, 'className': 'dt-body-center'},  // phone
                {'targets': 7, 'className': 'dt-body-center' }, // utype
                {'targets': 8, 'className': 'dt-body-center' }, // account_name
                {'targets': 9, 'className': 'dt-body-center' }, // account_number
                {'targets': 10, 'className': 'dt-body-right', // amount
                    'render': function (data, type, full, meta) { 
                        return AddComma(full.amount);
                    }
                },
                {'targets': 11, 'className': 'dt-body-center', // status
                    'render': function (data, type, full, meta) {
                        SET="";
                        if ( full.status == 0 )
                            SET = '<button type="button" class="btn btn-sm btn-danger" PointOutUser="'+full.useridkey+'">입금완료</button>';
                        else if ( full.status == 1 ) SET="본인 취소";
                        else if ( full.status == 2 ) SET="입금-종료";
                        return SET;
                    }
                },
            ],
            "initComplete": function(settings, json){
                UnLockScreen();
            }
        } );
    }
    /****************************************************/
    function AlertListTable() {
        var SNDList = {};
        LockScreen();
        $('#AlertList').DataTable( {
            "ajax": {
                "type" : "POST",
                "url" : "/processing/man_proc_alert_list.do",
                "data" : SNDList,
                "dataType": "JSON"
            },
            "autoWidth": false,
            "destroy": true,
            "pageLength": 10,
            "lengthMenu": [10, 20, 50, 100],
            "columns": [
                { "data": "seq" }, // 0 SEQ
                { "data": "idx" }, // 1
                { "data": "sdate" }, // 2
                { "data": "user" }, // 3
                { "data": "message" }, // 4
                { "data": "mtype" }, // 5
                { "data": "flag" }, // 6
            ],
            'columnDefs': [
                {'targets': 0, 'className': 'dt-body-center', 'searchable': false}, // seq
                {'targets': 1, 'className': 'dt-body-center', 'visible': false}, // idx
                {'targets': 2, 'className': 'dt-body-center', // sdate
                    'render': function (data, type, full, meta) { 
                        SET = "<a href='#' style='text-decoration:underline' MBox_Idx='"+full.idx+"'>" + full.sdate + "</a>";
                        return SET;
                    }
                },
                {'targets': 3, 'className': 'dt-body-center' }, // user
                {'targets': 4, 'className': 'dt-body-left', // message
                    'render': function (data, type, full, meta) {
                        SET = "<div>" + full.message + "</div>";
                        return SET;
                    }
                },
                {'targets': 5, 'className': 'dt-body-center' }, // mtype
                {'targets': 6, 'className': 'dt-body-center', // flag
                    'render': function (data, type, full, meta) { 
                        if ( parseInt(full.flag) == 1 )
                            SET = '<button type="button" class="btn btn-sm btn-danger" MBox_On_Idx="'+full.idx+'">복원</button>';
                        else
                            SET = '<button type="button" class="btn btn-sm btn-dark" MBox_Del_Idx="'+full.idx+'">삭제</button>';
                        return SET;
                    }
                },
            ],
            "initComplete": function(settings, json){
                UnLockScreen();
            }
        } );
    }
    /****************************************************/
    function GetCode() {
        var SNDList = {};
        // SNDList.isAll = 1;
        // SNDList.Name = "LangCode";
        // $.post("/processing/com_proc_get_code.do", SNDList, function(result) {
        //     if (result.isOK == 0) {
        //         alert("에러가 발생하였습니다.\n" + result.RText);
        //     } else { 
        //         SrcSEL = document.getElementById("SrcLang");
        //         TgtSEL = document.getElementById("TgtLang");
        //         for(var i in result.CodeList) {
        //             AddSelect(SrcSEL, result.CodeList[i].text, result.CodeList[i].code, -1);
        //             AddSelect(TgtSEL, result.CodeList[i].text, result.CodeList[i].code, -1);
        //         }
        //     } 
        // });

        // SNDList = {};
        // SNDList.isAll = 1;
        // SNDList.Name = "Service_Type";
        // $.post("/processing/com_proc_get_code.do", SNDList, function(result) {
        //     if (result.isOK == 0) {
        //         alert("에러가 발생하였습니다.\n" + result.RText);
        //     } else { 
        //         SVC_TypeSEL = document.getElementById("SVC_Type");
        //         for(var i in result.CodeList) {
        //             AddSelect(SVC_TypeSEL, result.CodeList[i].text, result.CodeList[i].code, -1);
        //         }
        //     } 
        // });

        // SNDList = {};
        // SNDList.isAll = 1;
        // SNDList.Name = "StateCode";
        // $.post("/processing/com_proc_get_code.do", SNDList, function(result) {
        //     if (result.isOK == 0) {
        //         alert("에러가 발생하였습니다.\n" + result.RText);
        //     } else { 
        //         TransTypeSEL = document.getElementById("Status");
        //         for(var i in result.CodeList) {
        //             AddSelect(TransTypeSEL, result.CodeList[i].text, result.CodeList[i].code, -1);
        //         }
        //     } 
        // });

        SNDList = {};
        LockScreen();
        $.post("/processing/man_proc_expert_list.do", SNDList, function(result) {
            UnLockScreen();
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            } else {
                ExList = result.ExpertList;

                ExpertSEL = document.getElementById("Expert");
                for(var i in ExList) {
                    AddSelect(ExpertSEL, ExList[i].name, ExList[i].useridkey, -1);
                }
                
                setTimeout(function() { UpdateTranReqTable(); }, 10);
            } 
        });
    }

    /***********************************************************/
    $('#AlertList').on('click', 'button', function (e) {
        isUpdate=-1;
        Idx = -1;
        if ( $(this).is("[MBox_On_Idx]") ) {
            isUpdate = 0;
            Idx = $(this).attr("MBox_On_Idx");
        }
        if ( $(this).is("[MBox_Del_Idx]") ) {
            isUpdate = 1;
            Idx = $(this).attr("MBox_Del_Idx");
        }

        if ( isUpdate > -1 && Idx > -1 ) {
            var SNDList = {};
            SNDList.isflag  = isUpdate;
            SNDList.Idx = Idx;
            LockScreen();
            $.post("/processing/man_proc_alert_onoff.do", SNDList, function(result) {
                UnLockScreen();
                if (result.isOK == 0) {
                    alert("에러가 발생하였습니다.\n" + result.RText);
                }
                else  {
                    $("#subMenu_7").trigger("click");
                }
            });
        }
    });
    var AlertEdit_Idx = -1;
    ////////////////////////////////////////////////
    function AlertEdit_Clean() {
        AlertEdit_Idx = -1;
        $('#AlertType').val('-').prop("selected",true);
        $("#AlertContent").val("");
    }
    //////////// ALERT SAVE ////////////
    function Alert_Save(MType, Content) {
        var SNDList = {};
        SNDList.Idx     = AlertEdit_Idx;
        SNDList.MType   = MType;
        SNDList.Content = Content;
        LockScreen();
        $.post("/processing/man_proc_alert_save.do", SNDList, function(result) {
            UnLockScreen();
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            }
            else  {
                alert("저장되었습니다.");
                $("#subMenu_7").trigger("click");
            }
        });
    }
    /***********************************************************/
    $('#AlertList').on('click', 'a', function (e) {
        if ( $(this).is("[MBox_Idx]") ) {
            var SNDList = {};
            SNDList.Idx = $(this).attr("MBox_Idx");
            LockScreen();
            $.post("/processing/man_proc_alert_get.do", SNDList, function(result) {
                UnLockScreen();
                if (result.isOK == 0) {
                    alert("에러가 발생하였습니다.\n" + result.RText);
                }
                else  {
                    AlertEdit_Idx = SNDList.Idx;
                    $('#AlertType').val(result.mtype).prop("selected",true);
                    $("#AlertContent").val(result.message);
                    $("#subMenu_8").trigger("click");
                }
            });
        }
    });
    /***********************************************************/
    $('#PointOutList').on('click', 'button', function (e) {
        if ( $(this).is("[PointOutUser]") ) {
            var SNDList = {};
            SNDList.UIdx = $(this).attr("PointOutUser");
            LockScreen();
            $.post("/processing/man_proc_pointout_close.do", SNDList, function(result) {
                UnLockScreen();
                if (result.isOK == 0) {
                    alert("에러가 발생하였습니다.\n" + result.RText);
                }
                else  {
                    $("#subMenu_6").trigger("click");
                }
            });
        }
    });
    /***********************************************************/
    $("#Btn_Search").on('click',function (e) {
        e.preventDefault();
        UpdateTranReqTable();
    });
    /***********************************************************/
    $("#Btn_User_Search").on('click',function (e) {
        e.preventDefault();
        UserListTable();
    });
    ////////////////////////////////////////////////
    $("#BTN_Alert_Save").on('click',function (e) {
        if ( $('#AlertType option:selected').val() == '-' ) {alert("공지 대상을 선택하여 주시기 바랍니다."); return;}
        if ( $("#AlertContent").val().length < 1 ) {alert("공지 내용을 입력해 주시기 바랍니다."); return;}
        
        Alert_Save($('#AlertType option:selected').val(), $("#AlertContent").val());
    });
    /***********************************************************/
    $("#subMenu_1, #subMenu_2, #subMenu_3, #subMenu_4, #subMenu_5, #subMenu_6, #subMenu_7, #subMenu_8").on('click',function (e) {
        e.preventDefault();
        $("#subMenu li a").removeClass("active");
        $(this).toggleClass("active");

        SelectedMenu = this.id.substr(8,1);
        if ( SelectedMenu < 5 ) {
            AlertEdit_Clean();
            UpdateTranReqTable();

            $("#LIST_AREA1").css("display", "block");
            $("#LIST_AREA2").css("display", "block");

            $("#USER_LIST").css("display", "none");
            $("#POINTOUT_LIST").css("display", "none");
            $("#ALERT_LIST").css("display", "none");
            $("#ALERT_EDIT").css("display", "none");
        }
        if ( SelectedMenu > 4 ) {
            $("#LIST_AREA1").css("display", "none");
            $("#LIST_AREA2").css("display", "none");
            $("#USER_LIST").css("display", "none");
            $("#POINTOUT_LIST").css("display", "none");
            $("#ALERT_LIST").css("display", "none");
            $("#ALERT_EDIT").css("display", "none");

            if ( SelectedMenu == 5 ) {
                $("#USER_LIST").css("display", "block");
                AlertEdit_Clean();
                UserListTable();
            }
            else if ( SelectedMenu == 6 ) {
                $("#POINTOUT_LIST").css("display", "block");
                AlertEdit_Clean();
                PointOutListTable();
            }
            else if ( SelectedMenu == 7 ) {
                $("#ALERT_LIST").css("display", "block");
                AlertEdit_Clean();
                AlertListTable();
            }
            else if ( SelectedMenu == 8 )
                $("#ALERT_EDIT").css("display", "block");
        }
    });

    if ( UserCheck == "isOn" ) {
        GetCode();
    }
