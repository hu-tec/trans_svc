<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_req_list');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

$SelectedMenu = 0;
if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$ExpertIDkey = $_SESSION['useridkey'];
	$svccode     = $_SESSION['svccode'];
	
	if ( isset( $_POST['SelectedMenu'] ) ) 
		$SelectedMenu = $_POST['SelectedMenu'];
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$Response = array();
$isOK = 1;
$UserType = 0;

$log->trace("*************** Manager : User's Qequest List Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $isOK == 1 ) {
	$sql = "SELECT utype, grade FROM User where svccode=".$svccode." && useridkey=".$ExpertIDkey;
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}
}
if ( $isOK == 1 ) {
	if( ($row = mysqli_fetch_array($DBQRet)) ) {
		$UserType = (int)$row['utype'];
	}
}

if ( $isOK == 1 ) {
	if ( $UserType == 99 || $UserType == 21 ) {}
	else {
		$isOK = 0;
		$ResText = "비정상 접속";
		$log->ERROR($ResText);
	}
}

if ( $isOK == 1 ) {
	$useridkey_list="(0)";
	if ( $isOK == 1 && isset( $_POST['UserName'] ) ) {
		$sql = "SELECT useridkey FROM User where svccode=1 and name like '%".$_POST['UserName']."%'";
		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
			$isOK = 0;
			$log->ERROR($ResText);
		}
		if ( $isOK == 1 ) {
			$useridkey_list="(0";
			$Cnt=1;
			while($row = mysqli_fetch_array($DBQRet)) {
				if ( $Cnt > 0 ) $useridkey_list=$useridkey_list.", ";
				$useridkey_list=$useridkey_list.$row['useridkey'];
				$Cnt++;
			}
			$useridkey_list=$useridkey_list.")";
		}
	}
}

if ( $isOK == 1 ) {
	$sql = "SELECT * FROM (";
	/* DOC */
	$sql = $sql."( SELECT";
	$sql = $sql." 0 as svctype,"; 
	$sql = $sql." (SELECT name FROM User WHERE MMS_Project.useridkey = User.useridkey) as user,";
	$sql = $sql." Purchase.sdate,";
	$sql = $sql." Purchase.pay_status,";
	$sql = $sql." hex(MMS_Job.projectname) as projectname,";
	$sql = $sql." hex(MMS_Job.tmp_fname) as job_name,";
	$sql = $sql." MMS_Job.jobid,";
	$sql = $sql." concat( (SELECT ko_text FROM LangCode WHERE code=MMS_Project.srcLang), '>', (SELECT ko_text FROM LangCode WHERE code=MMS_Project.tgtLang) ) as lang,";
	$sql = $sql." concat( MMS_Job.ori_fname, '.', MMS_Job.ext_file) as ori_fname,";
	$sql = $sql." MMS_Job.numofword as count,";
	$sql = $sql." MMS_Job.cost,";
	$sql = $sql." MMS_Job.trans_type,";
	$sql = $sql." MMS_Job.layout,";
	$sql = $sql." MMS_Job.urgent,";
	$sql = $sql." MMS_Job.qa_premium,";
	$sql = $sql." (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=MMS_Job.expert_category) as expert_category,";
	$sql = $sql." MMS_Job.prediction_time,";
	$sql = $sql." MMS_Job.expert_id,";
	$sql = $sql." MMS_Job.status";
	$sql = $sql." FROM MMS_Job, Purchase, MMS_Project";
	$sql = $sql." WHERE MMS_Job.flag=0 && Purchase.goods_key = MMS_Job.projectname && MMS_Job.projectname = MMS_Project.projectname";
	// Add Condition
	if ( $UserType == 99 ) { // 작업 할당
		if ( $SelectedMenu == 1 || $SelectedMenu == 2 ) {
			$sql = $sql." && Purchase.pay_status=1";
			if ( $SelectedMenu == 1 ) $sql = $sql." && MMS_Job.status=50";
			else if ( $SelectedMenu == 2 ) $sql = $sql." && MMS_Job.status=52";
		}
	}
	if ( $UserType == 21 ) {
		if ( $SelectedMenu == 1 )
			$sql = $sql." && MMS_Job.status=51";
		$sql = $sql." && MMS_Job.expert_id=".$ExpertIDkey;
	}
	// if ( isset( $_POST['UserName'] ) )       $sql = $sql." && MMS_Project.useridkey in ".$useridkey_list;
	if ( isset( $_POST['StartDate'] ) )      $sql = $sql." && DATE(MMS_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )        $sql = $sql." && DATE(MMS_Job.sdate) <= '".$_POST['EndDate']."'";
	// if ( isset( $_POST['SrcLang'] ) )        $sql = $sql." && MMS_Project.srcLang = '".$_POST['SrcLang']."'";
	// if ( isset( $_POST['TgtLang'] ) )        $sql = $sql." && MMS_Project.tgtLang = '".$_POST['TgtLang']."'";
	if ( isset( $_POST['SVCType'] ) ) { if ( (int)$_POST['SVCType'] != 0 ) $sql = $sql." && 1=0"; }
	if ( isset( $_POST['Expert'] ) )         $sql = $sql." && MMS_Job.expert_id = ".$_POST['Expert'];

	if ( isset( $_POST['Check_Urgent'] ) )   $sql = $sql." && MMS_Job.urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium'] ) ) $sql = $sql." && MMS_Job.qa_premium = ".$_POST['Check_QPremium'];
	if ( isset( $_POST['Check_Layout'] ) )   $sql = $sql." && MMS_Job.layout = ".$_POST['Check_Layout'];

	if ( isset( $_POST['Status'] ) )  {	
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && MMS_Job.status = 100";
		else $sql = $sql." && MMS_Job.status < 100";
	}

	////////////////
	$sql = $sql.")";

	/* TTS */
	$sql = $sql." UNION ALL";
	$sql = $sql." (SELECT"; 
	$sql = $sql." 1 as svctype,";
	$sql = $sql." (SELECT name FROM User WHERE MT_Job.useridkey = User.useridkey) as user,";
	$sql = $sql." Purchase.sdate,";
	$sql = $sql." Purchase.pay_status,";
	$sql = $sql." hex(MT_Job.projectname) as projectname,";
	$sql = $sql." if ( isnull(src_audio), '', hex(src_audio)) as job_name,";
	$sql = $sql." '' as jobid,";
	$sql = $sql." concat( (SELECT ko_text FROM LangCode WHERE code=MT_Job.srcLang), '>', (SELECT ko_text FROM LangCode WHERE code=MT_Job.tgtLang) ) as lang,";
	$sql = $sql." if ( isnull(tgt_audio), '', hex(tgt_audio)) as ori_fname,";
	$sql = $sql." MT_Job.numofchar as count,";
	$sql = $sql." MT_Job.cost,";
	$sql = $sql." MT_Job.trans_type,";
	$sql = $sql." 0 as layout,";
	$sql = $sql." MT_Job.urgent,";
	$sql = $sql." MT_Job.qa_premium,";
	$sql = $sql." (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=MT_Job.expert_category) as expert_category,";
	$sql = $sql." MT_Job.prediction_time,";
	$sql = $sql." MT_Job.expert_id,";
	$sql = $sql." MT_Job.status";
	$sql = $sql." FROM MT_Job, Purchase";
	$sql = $sql." WHERE MT_Job.flag=0 && Purchase.goods_key = MT_Job.projectname";
	// Add Condition
	if ( $UserType == 99 ) { // 작업 할당
		if ( $SelectedMenu == 1 || $SelectedMenu == 2 ) {
			$sql = $sql." && Purchase.pay_status=1";
			if ( $SelectedMenu == 1 ) $sql = $sql." && MT_Job.status=50";
			else if ( $SelectedMenu == 2 ) $sql = $sql." && MT_Job.status=52";
		}
	}
	if ( $UserType == 21 ) {
		if ( $SelectedMenu == 1 )
			$sql = $sql." && MT_Job.status=51";
		$sql = $sql." && MT_Job.expert_id=".$ExpertIDkey;
	}
	if ( isset( $_POST['UserName'] ) )      $sql = $sql." && MT_Job.useridkey in ".$useridkey_list;
	if ( isset( $_POST['StartDate'] ) )     $sql = $sql." && DATE(MT_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )       $sql = $sql." && DATE(MT_Job.sdate) <= '".$_POST['EndDate']."'";
	if ( isset( $_POST['SrcLang'] ) )       $sql = $sql." && MT_Job.srcLang = '".$_POST['SrcLang']."'";
	if ( isset( $_POST['TgtLang'] ) )       $sql = $sql." && MT_Job.tgtLang = '".$_POST['TgtLang']."'";
	if ( isset( $_POST['SVCType'] ) ) { if ( (int)$_POST['SVCType'] != 1 ) $sql = $sql." && 1=0"; }
	if ( isset( $_POST['Expert'] ) )        $sql = $sql." && MT_Job.expert_id = ".$_POST['Expert'];
	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && MT_Job.urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium']) ) $sql = $sql." && MT_Job.qa_premium = ".$_POST['Check_QPremium'];
	if ( isset( $_POST['Check_Layout'] ) )   $sql = $sql." && 1=0";
	if ( isset( $_POST['Status'] ) )  {	
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && MT_Job.status = 100";
		else $sql = $sql." && MT_Job.status < 100";
	}
	////////////////
	$sql = $sql.")";

	/* STT */
	$sql = $sql." UNION ALL";
	$sql = $sql." (SELECT"; 
	$sql = $sql." 2 as svctype,";
	$sql = $sql." (SELECT name FROM User WHERE STT_Job.useridkey = User.useridkey) as user,";
	$sql = $sql." Purchase.sdate,";
	$sql = $sql." Purchase.pay_status,";
	$sql = $sql." hex(STT_Job.projectname) as projectname,";
	$sql = $sql." if ( isnull(job_name), '', hex(job_name)) as job_name,";
	$sql = $sql." '' as jobid,";
	$sql = $sql." if ( tgtLang='-', (SELECT ko_text FROM LangCode WHERE code=STT_Job.srcLang), concat( (SELECT ko_text FROM LangCode WHERE code=STT_Job.srcLang), '>', (SELECT ko_text FROM LangCode WHERE code=STT_Job.tgtLang) ) ) as lang,";
//	$sql = $sql." concat( (SELECT ko_text FROM LangCode WHERE code=STT_Job.srcLang), '>', (SELECT ko_text FROM LangCode WHERE code=STT_Job.tgtLang) ) as lang,";
	$sql = $sql." ori_fname as ori_fname,";
	$sql = $sql." STT_Job.duration as count,";
	$sql = $sql." STT_Job.cost,";
	$sql = $sql." STT_Job.trans_type,";
	$sql = $sql." 0 as layout,";
	$sql = $sql." STT_Job.urgent,";
	$sql = $sql." STT_Job.qa_premium,";
	$sql = $sql." (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=STT_Job.expert_category) as expert_category,";
	$sql = $sql." STT_Job.prediction_time,";
	$sql = $sql." STT_Job.expert_id,";
	$sql = $sql." STT_Job.status";
	$sql = $sql." FROM STT_Job, Purchase";
	$sql = $sql." WHERE STT_Job.flag=0 && Purchase.goods_key = STT_Job.projectname";
	// Add Condition
	if ( $UserType == 99 ) { // 작업 할당
		if ( $SelectedMenu == 1 || $SelectedMenu == 2 ) {
			$sql = $sql." && Purchase.pay_status=1";
			if ( $SelectedMenu == 1 ) $sql = $sql." && STT_Job.status=50";
			else if ( $SelectedMenu == 2 ) $sql = $sql." && STT_Job.status=52";
		}
	}
	if ( $UserType == 21 ) {
		if ( $SelectedMenu == 1 )
			$sql = $sql." && STT_Job.status=51";
		$sql = $sql." && STT_Job.expert_id=".$ExpertIDkey;
	}
	if ( isset( $_POST['UserName'] ) )      $sql = $sql." && STT_Job.useridkey in ".$useridkey_list;
	if ( isset( $_POST['StartDate'] ) )     $sql = $sql." && DATE(STT_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )       $sql = $sql." && DATE(STT_Job.sdate) <= '".$_POST['EndDate']."'";
	if ( isset( $_POST['SrcLang'] ) )       $sql = $sql." && STT_Job.srcLang = '".$_POST['SrcLang']."'";
	if ( isset( $_POST['TgtLang'] ) )       $sql = $sql." && STT_Job.tgtLang = '".$_POST['TgtLang']."'";
	if ( isset( $_POST['SVCType'] ) ) { if ( (int)$_POST['SVCType'] != 2 ) $sql = $sql." && 1=0"; }
	if ( isset( $_POST['Expert'] ) )        $sql = $sql." && STT_Job.expert_id = ".$_POST['Expert'];
	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && STT_Job.urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium']) ) $sql = $sql." && STT_Job.qa_premium = ".$_POST['Check_QPremium'];
	if ( isset( $_POST['Check_Layout'] ) )   $sql = $sql." && 1=0";
	if ( isset( $_POST['Status'] ) )  {	
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && STT_Job.status = 100";
		else $sql = $sql." && STT_Job.status < 100";
	}
	////////////////
	$sql = $sql.")";

	/* VIDEO */
	$sql = $sql." UNION ALL";
	$sql = $sql." (SELECT"; 
	$sql = $sql." 3 as svctype,";
	$sql = $sql." (SELECT name FROM User WHERE VIDEO_Job.useridkey = User.useridkey) as user,";
	$sql = $sql." Purchase.sdate,";
	$sql = $sql." Purchase.pay_status,";
	$sql = $sql." hex(VIDEO_Job.projectname) as projectname,";
	$sql = $sql." if ( isnull(job_name), '', hex(job_name)) as job_name,";
	$sql = $sql." '' as jobid,";
	$sql = $sql." if ( tgtLang='-', (SELECT ko_text FROM LangCode WHERE code=VIDEO_Job.srcLang), concat( (SELECT ko_text FROM LangCode WHERE code=VIDEO_Job.srcLang), '>', (SELECT ko_text FROM LangCode WHERE code=VIDEO_Job.tgtLang) ) ) as lang,";
//	$sql = $sql." concat( (SELECT ko_text FROM LangCode WHERE code=VIDEO_Job.srcLang), '>', (SELECT ko_text FROM LangCode WHERE code=VIDEO_Job.tgtLang) ) as lang,";
	$sql = $sql." ori_fname as ori_fname,";
	$sql = $sql." VIDEO_Job.duration as count,";
	$sql = $sql." VIDEO_Job.cost,";
	$sql = $sql." VIDEO_Job.trans_type,";
	$sql = $sql." 0 as layout,";
	$sql = $sql." VIDEO_Job.urgent,";
	$sql = $sql." VIDEO_Job.qa_premium,";
	$sql = $sql." (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=VIDEO_Job.expert_category) as expert_category,";
	$sql = $sql." VIDEO_Job.prediction_time,";
	$sql = $sql." VIDEO_Job.expert_id,";
	$sql = $sql." VIDEO_Job.status";
	$sql = $sql." FROM VIDEO_Job, Purchase";
	$sql = $sql." WHERE VIDEO_Job.flag=0 && Purchase.goods_key = VIDEO_Job.projectname";
	// Add Condition
	if ( $UserType == 99 ) { // 작업 할당
		if ( $SelectedMenu == 1 || $SelectedMenu == 2 ) {
			$sql = $sql." && Purchase.pay_status=1";
			if ( $SelectedMenu == 1 ) $sql = $sql." && VIDEO_Job.status=50";
			else if ( $SelectedMenu == 2 ) $sql = $sql." && VIDEO_Job.status=52";
		}
	}
	if ( $UserType == 21 ) {
		if ( $SelectedMenu == 1 )
			$sql = $sql." && VIDEO_Job.status=51";
		$sql = $sql." && VIDEO_Job.expert_id=".$ExpertIDkey;
	}
	if ( isset( $_POST['UserName'] ) )      $sql = $sql." && VIDEO_Job.useridkey in ".$useridkey_list;
	if ( isset( $_POST['StartDate'] ) )     $sql = $sql." && DATE(VIDEO_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )       $sql = $sql." && DATE(VIDEO_Job.sdate) <= '".$_POST['EndDate']."'";
	if ( isset( $_POST['SrcLang'] ) )       $sql = $sql." && VIDEO_Job.srcLang = '".$_POST['SrcLang']."'";
	if ( isset( $_POST['TgtLang'] ) )       $sql = $sql." && VIDEO_Job.tgtLang = '".$_POST['TgtLang']."'";
	if ( isset( $_POST['SVCType'] ) ) { if ( (int)$_POST['SVCType'] != 3 ) $sql = $sql." && 1=0"; }
	if ( isset( $_POST['Expert'] ) )        $sql = $sql." && VIDEO_Job.expert_id = ".$_POST['Expert'];
	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && VIDEO_Job.urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium']) ) $sql = $sql." && VIDEO_Job.qa_premium = ".$_POST['Check_QPremium'];
	if ( isset( $_POST['Check_Layout'] ) )   $sql = $sql." && 1=0";
	if ( isset( $_POST['Status'] ) )  {	
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && VIDEO_Job.status = 100";
		else $sql = $sql." && VIDEO_Job.status < 100";
	}
	////////////////
	$sql = $sql.")";

	/* S2S */
	$sql = $sql." UNION ALL";
	$sql = $sql." (SELECT"; 
	$sql = $sql." 4 as svctype,";
	$sql = $sql." (SELECT name FROM User WHERE S2S_Job.useridkey = User.useridkey) as user,";
	$sql = $sql." Purchase.sdate,";
	$sql = $sql." Purchase.pay_status,";
	$sql = $sql." hex(S2S_Job.projectname) as projectname,";
	$sql = $sql." if ( isnull(job_name), '', hex(job_name)) as job_name,";
	$sql = $sql." '' as jobid,";
	$sql = $sql." if ( tgtLang='-', (SELECT ko_text FROM LangCode WHERE code=S2S_Job.srcLang), concat( (SELECT ko_text FROM LangCode WHERE code=S2S_Job.srcLang), '>', (SELECT ko_text FROM LangCode WHERE code=S2S_Job.tgtLang) ) ) as lang,";
//	$sql = $sql." concat( (SELECT ko_text FROM LangCode WHERE code=S2S_Job.srcLang), '>', (SELECT ko_text FROM LangCode WHERE code=S2S_Job.tgtLang) ) as lang,";
	$sql = $sql." ori_fname as ori_fname,";
	$sql = $sql." S2S_Job.duration as count,";
	$sql = $sql." S2S_Job.cost,";
	$sql = $sql." S2S_Job.trans_type,";
	$sql = $sql." 0 as layout,";
	$sql = $sql." S2S_Job.urgent,";
	$sql = $sql." S2S_Job.qa_premium,";
	$sql = $sql." (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=S2S_Job.expert_category) as expert_category,";
	$sql = $sql." S2S_Job.prediction_time,";
	$sql = $sql." S2S_Job.expert_id,";
	$sql = $sql." S2S_Job.status";
	$sql = $sql." FROM S2S_Job, Purchase";
	$sql = $sql." WHERE S2S_Job.flag=0 && Purchase.goods_key = S2S_Job.projectname";
	// Add Condition
	if ( $UserType == 99 ) { // 작업 할당
		if ( $SelectedMenu == 1 || $SelectedMenu == 2 ) {
			$sql = $sql." && Purchase.pay_status=1";
			if ( $SelectedMenu == 1 ) $sql = $sql." && S2S_Job.status=50";
			else if ( $SelectedMenu == 2 ) $sql = $sql." && S2S_Job.status=52";
		}
	}
	if ( $UserType == 21 ) {
		if ( $SelectedMenu == 1 )
			$sql = $sql." && S2S_Job.status=51";
		$sql = $sql." && S2S_Job.expert_id=".$ExpertIDkey;
	}
	if ( isset( $_POST['UserName'] ) )      $sql = $sql." && S2S_Job.useridkey in ".$useridkey_list;
	if ( isset( $_POST['StartDate'] ) )     $sql = $sql." && DATE(S2S_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )       $sql = $sql." && DATE(S2S_Job.sdate) <= '".$_POST['EndDate']."'";
	if ( isset( $_POST['SrcLang'] ) )       $sql = $sql." && S2S_Job.srcLang = '".$_POST['SrcLang']."'";
	if ( isset( $_POST['TgtLang'] ) )       $sql = $sql." && S2S_Job.tgtLang = '".$_POST['TgtLang']."'";
	if ( isset( $_POST['SVCType'] ) ) { if ( (int)$_POST['SVCType'] != 3 ) $sql = $sql." && 1=0"; }
	if ( isset( $_POST['Expert'] ) )        $sql = $sql." && S2S_Job.expert_id = ".$_POST['Expert'];
	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && S2S_Job.urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium']) ) $sql = $sql." && S2S_Job.qa_premium = ".$_POST['Check_QPremium'];
	if ( isset( $_POST['Check_Layout'] ) )   $sql = $sql." && 1=0";
	if ( isset( $_POST['Status'] ) )  {	
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && S2S_Job.status = 100";
		else $sql = $sql." && S2S_Job.status < 100";
	}
	////////////////
	$sql = $sql.")";

	/* YOUTUBE */
	$sql = $sql." UNION ALL";
	$sql = $sql." (SELECT"; 
	$sql = $sql." 5 as svctype,";
	$sql = $sql." (SELECT name FROM User WHERE YOUTUBE_Job.useridkey = User.useridkey) as user,";
	$sql = $sql." Purchase.sdate,";
	$sql = $sql." Purchase.pay_status,";
	$sql = $sql." hex(YOUTUBE_Job.projectname) as projectname,";
	$sql = $sql." if ( isnull(job_name), '', hex(job_name)) as job_name,";
	$sql = $sql." '' as jobid,";
	$sql = $sql." if ( tgtLang='-', (SELECT ko_text FROM LangCode WHERE code=YOUTUBE_Job.srcLang), concat( (SELECT ko_text FROM LangCode WHERE code=YOUTUBE_Job.srcLang), '>', (SELECT ko_text FROM LangCode WHERE code=YOUTUBE_Job.tgtLang) ) ) as lang,";
//	$sql = $sql." concat( (SELECT ko_text FROM LangCode WHERE code=YOUTUBE_Job.srcLang), '>', (SELECT ko_text FROM LangCode WHERE code=YOUTUBE_Job.tgtLang) ) as lang,";
	$sql = $sql." ori_fname as ori_fname,";
	$sql = $sql." YOUTUBE_Job.duration as count,";
	$sql = $sql." YOUTUBE_Job.cost,";
	$sql = $sql." YOUTUBE_Job.trans_type,";
	$sql = $sql." 0 as layout,";
	$sql = $sql." YOUTUBE_Job.urgent,";
	$sql = $sql." YOUTUBE_Job.qa_premium,";
	$sql = $sql." (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=YOUTUBE_Job.expert_category) as expert_category,";
	$sql = $sql." YOUTUBE_Job.prediction_time,";
	$sql = $sql." YOUTUBE_Job.expert_id,";
	$sql = $sql." YOUTUBE_Job.status";
	$sql = $sql." FROM YOUTUBE_Job, Purchase";
	$sql = $sql." WHERE YOUTUBE_Job.flag=0 && Purchase.goods_key = YOUTUBE_Job.projectname";
	// Add Condition
	if ( $UserType == 99 ) { // 작업 할당
		if ( $SelectedMenu == 1 || $SelectedMenu == 2 ) {
			$sql = $sql." && Purchase.pay_status=1";
			if ( $SelectedMenu == 1 ) $sql = $sql." && YOUTUBE_Job.status=50";
			else if ( $SelectedMenu == 2 ) $sql = $sql." && YOUTUBE_Job.status=52";
		}
	}
	if ( $UserType == 21 ) {
		if ( $SelectedMenu == 1 )
			$sql = $sql." && YOUTUBE_Job.status=51";
		$sql = $sql." && YOUTUBE_Job.expert_id=".$ExpertIDkey;
	}
	if ( isset( $_POST['UserName'] ) )      $sql = $sql." && YOUTUBE_Job.useridkey in ".$useridkey_list;
	if ( isset( $_POST['StartDate'] ) )     $sql = $sql." && DATE(YOUTUBE_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )       $sql = $sql." && DATE(YOUTUBE_Job.sdate) <= '".$_POST['EndDate']."'";
	if ( isset( $_POST['SrcLang'] ) )       $sql = $sql." && YOUTUBE_Job.srcLang = '".$_POST['SrcLang']."'";
	if ( isset( $_POST['TgtLang'] ) )       $sql = $sql." && YOUTUBE_Job.tgtLang = '".$_POST['TgtLang']."'";
	if ( isset( $_POST['SVCType'] ) ) { if ( (int)$_POST['SVCType'] != 3 ) $sql = $sql." && 1=0"; }
	if ( isset( $_POST['Expert'] ) )        $sql = $sql." && YOUTUBE_Job.expert_id = ".$_POST['Expert'];
	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && YOUTUBE_Job.urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium']) ) $sql = $sql." && YOUTUBE_Job.qa_premium = ".$_POST['Check_QPremium'];
	if ( isset( $_POST['Check_Layout'] ) )   $sql = $sql." && 1=0";
	if ( isset( $_POST['Status'] ) )  {	
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && YOUTUBE_Job.status = 100";
		else $sql = $sql." && YOUTUBE_Job.status < 100";
	}
	////////////////
	$sql = $sql.")";

	///////////////////////////////////////////////////////////
	$sql = $sql.") T ORDER BY sdate desc limit 0, 1000";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}
}

if ( $isOK == 1 ) {
	$TotRec = array();
	$cnt=1;
	while($row = mysqli_fetch_array($DBQRet)) {
		$OneRec = array();

		$OneRec["seq"]             = $cnt;
		$OneRec["svctype"]         = $row['svctype'];
		$RBizType = (int)$OneRec["svctype"];
	
		if ( $UserType == 99 )
			$OneRec["user"]            = $row['user'];

		$OneRec["sdate"]           = $row['sdate'];
		$OneRec["projectname"]     = strtolower($row['projectname']);
		$OneRec["jobname"]         = strtolower($row['job_name']);
		$OneRec["lang"]            = $row['lang'];
		
		if ( $RBizType == 0 ||  (2 <= $RBizType && $RBizType <= 5)) { // DOC, tts(x), STS/Video/S2S/Youtube
			$OneRec["ori_fname"] = $row['ori_fname'];
			if (class_exists('Normalizer')) {
				if (Normalizer::isNormalized($OneRec["ori_fname"], Normalizer::FORM_D))
					$OneRec["ori_fname"]= Normalizer::normalize($OneRec["ori_fname"], Normalizer::FORM_C);
			}
		}
		else
			$OneRec["ori_fname"] = strtolower($row['ori_fname']);
		
		$OneRec["count"]       = $row['count'];

		if ( $UserType == 99 )
			$OneRec["cost"]            = $row['cost'];
	
		$OneRec["prediction_time"] = $row['prediction_time'];
		$OneRec["trans_type"]      = $row['trans_type'];
		$OneRec["layout"]          = $row['layout'];
		$OneRec["urgent"]          = $row['urgent'];
		$OneRec["qa_premium"]      = $row['qa_premium'];
		$OneRec["expert_category"] = $row['expert_category'];

		if ( $UserType == 99 )
			$OneRec["expert_id"]       = $row['expert_id'];
		
		$OneRec["status"]       = $row['status'];
		$OneRec["jobid"]       = $row['jobid'];

		$OneRec["exist_file_1"] = 0;
		$OneRec["exist_file_2"] = 0;
		if ( $RBizType  == 0 ) { // DOC
			if( file_exists($DownFilePath.$OneRec["jobname"]) )
				$OneRec["exist_file_1"] = 1;
		}
		else if ( $RBizType  == 1 ) { // TTS
			if( file_exists($DownFilePath.$OneRec["jobname"].".mp3") )
				$OneRec["exist_file_1"] = 1;
			if( file_exists($DownFilePath.$OneRec["ori_fname"].".mp3") )
				$OneRec["exist_file_2"] = 1;
		}
		else if ( 2 <= $RBizType && $RBizType <= 5 ) { //STS/Video/S2S/Youtube
			if( file_exists($UpFilePath.$OneRec["jobname"].".mp3") )
				$OneRec["exist_file_1"] = 1;

			if ( $RBizType == 4 ) { // S2S
				if( file_exists($DownFilePath.$OneRec["jobname"].".mp3") )
					$OneRec["exist_file_2"] = 1;
			}
		}
	
		$TotRec[] = $OneRec;
		$cnt++;
		//$log->trace("ONE : \n".json_encode($OneRec));
	}
	
	//$log->trace("TOT : \n".json_encode($TotRec));
	//$Response["iTotalRecords"] = ($cnt-1);
	$Response["data"] = $TotRec;
}
mysqli_close($DBCon);

$log->trace("RES : \n".json_encode($Response));

print json_encode($Response);
?>
