    /**********************************************************************/
    function QuotationSection_ONOFF(Display_Opt) {
        $("#QuotationSection").css('display', Display_Opt);
    }
    /**********************************************************************/
    function AddExpertOpt(id, ListData) {
        ELSEL = document.getElementById(id);

        for(var i in ListData) {
            ELOpt = document.createElement('option');
            ELOpt.value = ListData[i].code;
            ELOpt.text  = ListData[i].text;
            ELSEL.appendChild(ELOpt);
        }
    }
    /****************************************************/
    function GetExpertCode() {
        var SNDList = {};
        SNDList.isAll = 0;
        SNDList.Name = "Expert_Category";
        LockScreen();
        $.post("/processing/com_proc_get_code.do", SNDList, function(result) {
            UnLockScreen();
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            } else { 
                AddExpertOpt("Select_Premium", result.CodeList);
                $("#Select_Premium").val("-").prop("selected", true);

                setTimeout(function() { UpdateDocTranTable(); }, 10);
            } 
        });
    }

    /**********************************/
    $("#Select_Premium").on('click', function(e){
        e.stopPropagation();
        e.preventDefault();
    });
    /**********************************/
    function CalcCost() {
        isCalculation = 1;

        var SNDList = {};
        SNDList.BizType    = BizType;
        SNDList.Trans_Type = Trans_Type;
        SNDList.AI_UType   = 0;
        SNDList.Layout     = Trans_Layout;
        SNDList.QPremium   = Trans_QAPremium;
        SNDList.Urgent     = Trans_Urgent;

        SNDList.ExpertCategory = $("#Select_Premium option:selected").val();
        if ( SNDList.ExpertCategory.length < 1 ) SNDList.ExpertCategory = '-';

// console.log("Trans_Type : " + Trans_Type + ", Trans_Layout : " + Trans_Layout + ", Trans_QAPremium : " + Trans_QAPremium + ", Trans_Urgent : " + Trans_Urgent);

        // Proc = "";
        // if ( BizType == 0 ) Proc = "/processing/doc_proc_calc_cost.do";
        // else if ( BizType == 1 ) Proc = "/processing/tts_proc_calc_cost.do";
        // else if ( 2<= BizType && BizType <= 5 ) Proc = "/processing/speech_proc_calc_cost.do"; 

        Proc = "/processing/com_proc_calc_cost.do"; 

        LockScreen();
        $.post(Proc, SNDList, function(result) {
            UnLockScreen();
            if (result.isOK == 0) {
                alert("에러가 발생하였습니다.\n" + result.RText);
            } else {
                TotalCost = result.TotalCost;
                PredictionTime = result.PredictionTime;
                
                UpdateDocTranTable();
            } 
        });
    }

    /******************** Type of translation ***************************************/
    function Clear_All_Selected() {
        $("#BTN_AddSelect li").removeClass('active');
    }
    function Selected_Type_Clear() {
        $("#BTN_Type li").removeClass('active');
        Clear_All_Selected();
    }
    function Selected_Type_Switch( Obj ) {
        Selected_Type_Clear();
        $(Obj).addClass('active');
    }
    function Set_Add_Option(onPremium, onUrgent) {
        $("#BTN_Quality_Premium").css("display", onPremium==1?"flex":"none");
        $("#BTN_Urgent").css("display", onUrgent==1?"flex":"none");
    }

    /******************** Select PURCHASE  ***************************************/
    /******************** Select Service Type  ***************************************/
    $("#BTNType_Basic, #BTNType_STandard, #BTNType_Deluxe, #BTNType_Premium").on('click', function(e) {
        if ( this.id == "BTNType_Basic" && Trans_Type==1) return;
        else if ( this.id == "BTNType_STandard" && Trans_Type==2) return;
        else if ( this.id == "BTNType_Deluxe" && Trans_Type==3) return;
        else if ( this.id == "BTNType_Premium" && Trans_Type==4) return;

        /////// For TTS, STT, Video, Youtube
        if ( BizType == 1 || BizType == 2 || BizType == 3 || BizType == 5 ) {
            NeedTrans = 1;
            if ( BizType == 1 ) { // TTS
                if ( this.id == "BTNType_Basic" ) NeedTrans = 0;
            }
            else if ( BizType == 2 || BizType == 3 || BizType == 5 ) { // STT, Video, Youtube
                if ( this.id == "BTNType_Basic" || this.id == "BTNType_STandard" ) NeedTrans = 0;
            }

            if ( NeedTrans == 0 ) {
                if ( $("#TgtLang option:selected").val() != '-' ) {
                    alert("번역할 언어를 선택하셨습니다.\n[번역 안함]을 선택해 주시기 바랍니다.");
                    return false;
                }
            }
            else {
                if ( $("#TgtLang option:selected").val() == '-' ) {
                    alert("번역할 언어를 선택하여 주시기 바랍니다.");
                    return false;
                }
            }
        }
        ///////////////////////////
        $("#PurchaseSection").css('display', "block");

        if ( this.id == "BTNType_Basic" ) {
            Trans_Type=1;
            Set_Add_Option(0, 0);
        }
        else if ( this.id == "BTNType_STandard" ) {
            Trans_Type=2;
            if ( BizType == 2 || BizType == 3 || BizType == 5  ) // STT, Video, Youtube
                Set_Add_Option(0, 1);
            else
                Set_Add_Option(0, 0);
        }
        else if ( this.id == "BTNType_Deluxe" || this.id == "BTNType_Premium" ) {
            if ( this.id == "BTNType_Deluxe" ) Trans_Type=3;
            else if ( this.id == "BTNType_Premium" ) Trans_Type=4;
            Set_Add_Option(1, 1);
        }

        Trans_Layout = 0;
        Trans_QAPremium = 0;
        Trans_Urgent = 0;
        Selected_Type_Switch( this );

        if ( BizType == 1 ) // TTS : Text Save
            Save_Text(); // at trans_tts.js function
        else CalcCost();
    });

    /********************  Option Select ***************************************/
    function Add_Selected_Switch( Obj, isOff ) {
        if ( isOff ) $(Obj).removeClass('active');
        else         $(Obj).addClass('active');
    }
    /******************** Select Option Type  ***************************************/
    $("#BTN_File_Layout, #BTN_Quality_Premium, #BTN_Urgent").on('click', function(e) {
        if ( Trans_Type == 0 ) return;

        if ( this.id == "BTN_File_Layout" ) {
            Add_Selected_Switch(this, Trans_Layout);
            Trans_Layout = Math.abs(Trans_Layout-1);
        }
        else if ( this.id == "BTN_Quality_Premium" ) {
            Add_Selected_Switch(this, Trans_QAPremium);
            Trans_QAPremium = Math.abs(Trans_QAPremium-1);
        }
        else if ( this.id == "BTN_Urgent" ) {
            Add_Selected_Switch(this, Trans_Urgent);
            Trans_Urgent = Math.abs(Trans_Urgent-1);
        }
        if ( Trans_QAPremium == 0) $("#Select_Premium").val("-").prop("selected", true);

        CalcCost();
    });
    