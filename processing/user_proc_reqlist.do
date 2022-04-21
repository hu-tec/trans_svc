<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('user_proc_reqlist');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$useridkey = $_SESSION['useridkey'];
$svccode   = $_SESSION['svccode'];

$Response = array();
$TotRec = array();
$isOK = 1;

$log->trace("*************** Information Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $isOK == 1 ) {
	$log->INFO("*** UserSeq=".$_SESSION['useridkey']);
	
	// DB Query
	$sql = "SELECT * FROM (";
	/* DOC */
	$sql = $sql."(SELECT 0 as svctype, hex(MMS_Project.projectname) as projectname, MMS_Project.sdate as sdate,";
	$sql = $sql."	concat(";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = MMS_Project.srcLang), '>',";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = MMS_Project.tgtLang)";
	$sql = $sql."	) as lang,";
	$sql = $sql."	hex(MMS_Job.tmp_fname) as fname1,";
	$sql = $sql."	concat(MMS_Job.ori_fname, '.', MMS_Job.ext_file) as fname2,";
	$sql = $sql."	numofword as size, prediction_time, cost, status, trans_type, layout, qa_premium, urgent,"; 
	$sql = $sql."	if ( (expert_category='' || expert_category='-'), '', (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=expert_category)) as expert_category";
	$sql = $sql."	FROM MMS_Project, MMS_Job";
	$sql = $sql."	WHERE MMS_Job.flag=0 && MMS_Project.projectname = MMS_Job.projectname && MMS_Project.svccode = ".$_SESSION['svccode']." && MMS_Project.useridkey = ".$_SESSION['useridkey'];
	if ( isset( $_POST['isAll'] ) ) {
		if ( (int)$_POST['isAll'] == 0 ) {
			if ( isset( $_POST['svctype'] ) ) { 
				if ( (int)$_POST['svctype'] != 0 ) $sql = $sql." && 1=0";
			}
		}
	}
	if ( isset( $_POST['StartDate'] ) )  $sql = $sql." && DATE(MMS_Project.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )  $sql = $sql." && DATE(MMS_Project.sdate) <= '".$_POST['EndDate']."'";

	if ( isset( $_POST['Status'] ) ) {
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && status = 100";
		else $sql = $sql." && status < 100";
	}

	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium'] ) )  $sql = $sql." && qa_premium = ".$_POST['Check_QPremium'];
	if ( isset( $_POST['Check_Layout'] ) )  $sql = $sql." && layout = ".$_POST['Check_Layout'];
	$sql = $sql.")";

	/* TTS */
	$sql = $sql." UNION ";
	$sql = $sql."(SELECT 1 as svctype, hex(MT_Job.projectname) as projectname, sdate,";
	$sql = $sql."	if ( tgtLang='-', (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang), ";
	$sql = $sql."		concat(";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang), '>',";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = tgtLang))";
	$sql = $sql."	) as lang,";
	$sql = $sql."	if ( isnull(src_audio), '', hex(src_audio)) as fname1, if ( isnull(tgt_audio), '', hex(tgt_audio)) as fname2,";
	$sql = $sql."	numofchar as size, prediction_time, cost, status, trans_type, 0, qa_premium, urgent,";
	$sql = $sql."	if ( (expert_category='' || expert_category='-'), '', (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=expert_category)) as expert_category";
	$sql = $sql."	FROM MT_Job";
	$sql = $sql."	WHERE MT_Job.flag=0 && MT_Job.svccode = ".$_SESSION['svccode']." && MT_Job.useridkey = ".$_SESSION['useridkey'];
	if ( isset( $_POST['isAll'] ) ) {
		if ( (int)$_POST['isAll'] == 0 ) {
			if ( isset( $_POST['svctype'] ) ) { 
				if ( (int)$_POST['svctype'] != 1 ) $sql = $sql." && 1=0";
			}
		}
	}
	if ( isset( $_POST['StartDate'] ) )  $sql = $sql." && DATE(MT_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )  $sql = $sql." && DATE(MT_Job.sdate) <= '".$_POST['EndDate']."'";

	if ( isset( $_POST['Status'] ) ) {
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && status = 100";
		else $sql = $sql." && status < 100";
	}

	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium'] ) )  $sql = $sql." && qa_premium = ".$_POST['Check_QPremium'];
	$sql = $sql.")";

	/* STT */
	$sql = $sql." UNION ";
	$sql = $sql."(SELECT 2 as svctype, hex(STT_Job.projectname) as projectname, sdate,";
	$sql = $sql."	if ( tgtLang='-', (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang), ";
	$sql = $sql."		concat(";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang), '>',";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = tgtLang))";
	$sql = $sql."	) as lang,";
	$sql = $sql."	if ( isnull(job_name), '', hex(job_name)) as fname1, ori_fname as fname2,";
	$sql = $sql."	duration as size, prediction_time, cost, status, trans_type, 0, qa_premium, urgent,";
	$sql = $sql."	if ( (expert_category='' || expert_category='-'), '', (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=expert_category)) as expert_category";
	$sql = $sql."	FROM STT_Job";
	$sql = $sql."	WHERE STT_Job.flag=0 && STT_Job.svccode = ".$_SESSION['svccode']." && STT_Job.useridkey = ".$_SESSION['useridkey'];
	if ( isset( $_POST['isAll'] ) ) {
		if ( (int)$_POST['isAll'] == 0 ) {
			if ( isset( $_POST['svctype'] ) ) { 
				if ( (int)$_POST['svctype'] != 2 ) $sql = $sql." && 1=0";
			}
		}
	}
	if ( isset( $_POST['StartDate'] ) )  $sql = $sql." && DATE(STT_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )  $sql = $sql." && DATE(STT_Job.sdate) <= '".$_POST['EndDate']."'";

	if ( isset( $_POST['Status'] ) ) {
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && status = 100";
		else $sql = $sql." && status < 100";
	}

	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium'] ) )  $sql = $sql." && qa_premium = ".$_POST['Check_QPremium'];
	$sql = $sql.")";

	/* VIDEO */
	$sql = $sql." UNION ";
	$sql = $sql."(SELECT 3 as svctype, hex(VIDEO_Job.projectname) as projectname, sdate,";
	$sql = $sql."	if ( tgtLang='-', (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang), ";
	$sql = $sql."		concat(";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang), '>',";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = tgtLang))";
	$sql = $sql."	) as lang,";
	$sql = $sql."	if ( isnull(job_name), '', hex(job_name)) as fname1, ori_fname as fname2,";
	$sql = $sql."	duration as size, prediction_time, cost, status, trans_type, 0, qa_premium, urgent,";
	$sql = $sql."	if ( (expert_category='' || expert_category='-'), '', (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=expert_category)) as expert_category";
	$sql = $sql."	FROM VIDEO_Job";
	$sql = $sql."	WHERE VIDEO_Job.flag=0 && VIDEO_Job.svccode = ".$_SESSION['svccode']." && VIDEO_Job.useridkey = ".$_SESSION['useridkey'];
	if ( isset( $_POST['isAll'] ) ) {
		if ( (int)$_POST['isAll'] == 0 ) {
			if ( isset( $_POST['svctype'] ) ) { 
				if ( (int)$_POST['svctype'] != 3 ) $sql = $sql." && 1=0";
			}
		}
	}
	if ( isset( $_POST['StartDate'] ) )  $sql = $sql." && DATE(VIDEO_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )  $sql = $sql." && DATE(VIDEO_Job.sdate) <= '".$_POST['EndDate']."'";

	if ( isset( $_POST['Status'] ) ) {
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && status = 100";
		else $sql = $sql." && status < 100";
	}

	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium'] ) )  $sql = $sql." && qa_premium = ".$_POST['Check_QPremium'];
	$sql = $sql.")";

	/* S2S */
	$sql = $sql." UNION ";
	$sql = $sql."(SELECT 4 as svctype, hex(S2S_Job.projectname) as projectname, sdate,";
	$sql = $sql."	if ( tgtLang='-', (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang), ";
	$sql = $sql."		concat(";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang), '>',";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = tgtLang))";
	$sql = $sql."	) as lang,";
	$sql = $sql."	if ( isnull(job_name), '', hex(job_name)) as fname1, ori_fname as fname2,";
	$sql = $sql."	duration as size, prediction_time, cost, status, trans_type, 0, qa_premium, urgent,";
	$sql = $sql."	if ( (expert_category='' || expert_category='-'), '', (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=expert_category)) as expert_category";
	$sql = $sql."	FROM S2S_Job";
	$sql = $sql."	WHERE S2S_Job.flag=0 && S2S_Job.svccode = ".$_SESSION['svccode']." && S2S_Job.useridkey = ".$_SESSION['useridkey'];
	if ( isset( $_POST['isAll'] ) ) {
		if ( (int)$_POST['isAll'] == 0 ) {
			if ( isset( $_POST['svctype'] ) ) { 
				if ( (int)$_POST['svctype'] != 2 ) $sql = $sql." && 1=0";
			}
		}
	}
	if ( isset( $_POST['StartDate'] ) )  $sql = $sql." && DATE(S2S_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )  $sql = $sql." && DATE(S2S_Job.sdate) <= '".$_POST['EndDate']."'";

	if ( isset( $_POST['Status'] ) ) {
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && status = 100";
		else $sql = $sql." && status < 100";
	}

	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium'] ) )  $sql = $sql." && qa_premium = ".$_POST['Check_QPremium'];
	$sql = $sql.")";

	/* YOUTUBE */
	$sql = $sql." UNION ";
	$sql = $sql."(SELECT 5 as svctype, hex(YOUTUBE_Job.projectname) as projectname, sdate,";
	$sql = $sql."	if ( tgtLang='-', (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang), ";
	$sql = $sql."		concat(";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang), '>',";
	$sql = $sql."		(SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = tgtLang))";
	$sql = $sql."	) as lang,";
	$sql = $sql."	if ( isnull(job_name), '', hex(job_name)) as fname1, ori_fname as fname2,";
	$sql = $sql."	duration as size, prediction_time, cost, status, trans_type, 0, qa_premium, urgent,";
	$sql = $sql."	if ( (expert_category='' || expert_category='-'), '', (SELECT ko_text FROM Expert_Category WHERE Expert_Category.code=expert_category)) as expert_category";
	$sql = $sql."	FROM YOUTUBE_Job";
	$sql = $sql."	WHERE YOUTUBE_Job.flag=0 && YOUTUBE_Job.svccode = ".$_SESSION['svccode']." && YOUTUBE_Job.useridkey = ".$_SESSION['useridkey'];
	if ( isset( $_POST['isAll'] ) ) {
		if ( (int)$_POST['isAll'] == 0 ) {
			if ( isset( $_POST['svctype'] ) ) { 
				if ( (int)$_POST['svctype'] != 2 ) $sql = $sql." && 1=0";
			}
		}
	}
	if ( isset( $_POST['StartDate'] ) )  $sql = $sql." && DATE(YOUTUBE_Job.sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )  $sql = $sql." && DATE(YOUTUBE_Job.sdate) <= '".$_POST['EndDate']."'";

	if ( isset( $_POST['Status'] ) ) {
		if ( (int)$_POST['Status'] == 100 ) $sql = $sql." && status = 100";
		else $sql = $sql." && status < 100";
	}

	if ( isset( $_POST['Check_Urgent'] ) )  $sql = $sql." && urgent = ".$_POST['Check_Urgent'];
	if ( isset( $_POST['Check_QPremium'] ) )  $sql = $sql." && qa_premium = ".$_POST['Check_QPremium'];
	$sql = $sql.")";
	/////////////////////////////////////////////////////////////

	$sql = $sql.") T ORDER BY sdate desc limit 0, 1000";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}
}

if ( $isOK == 1 ) {
	$cnt=1;
	while($row = mysqli_fetch_array($DBQRet)) {
		$OneRec = array();

		$OneRec["seq"]     = $cnt;

		$OneRec["svctype"] =  $row['svctype'];
		$RBizType = (int)$OneRec["svctype"];

		$OneRec["projectname"] = strtolower($row['projectname']);

		$OneRec["sdate"]   =  $row['sdate'];

		$OneRec["lang"]    = $row['lang'];

		$OneRec["fname1"]  = strtolower($row['fname1']);

		if ( (int)$row['svctype'] != 1 ) { // is not TTS
			$OneRec["fname2"]  = $row['fname2'];
			if (class_exists('Normalizer')) {
				if (Normalizer::isNormalized($OneRec["fname2"], Normalizer::FORM_D))
					$OneRec["fname2"]= Normalizer::normalize($OneRec["fname2"], Normalizer::FORM_C);
			}		
		}
		else $OneRec["fname2"]  = strtolower($row['fname2']);

		$OneRec["size"]   = $row['size'];
		$OneRec["prediction_time"] = $row['prediction_time'];
		$OneRec["cost"]   = $row['cost'];
		$OneRec["status"] = $row['status'];

		$OneRec["trans_type"]      = $row['trans_type'];
		$OneRec["layout"]          = $row['layout'];
		$OneRec["qa_premium"]      = $row['qa_premium'];
		$OneRec["urgent"]          = $row['urgent'];
		$OneRec["expert_category"] = $row['expert_category'];

		$OneRec["exist_file_1"] = 0;
		$OneRec["exist_file_2"] = 0;
		if ( $RBizType  == 0 ) { // DOC
			if( file_exists($DownFilePath.$OneRec["fname1"]) )
				$OneRec["exist_file_1"] = 1;
		}
		else if ( $RBizType  == 1 ) { // TTS
			if( file_exists($DownFilePath.$OneRec["fname1"].".mp3") )
				$OneRec["exist_file_1"] = 1;
			if( file_exists($DownFilePath.$OneRec["fname2"].".mp3") )
				$OneRec["exist_file_2"] = 1;
		}
		else if ( 2<= $RBizType && $RBizType <= 5 ) { // STT, Video, S2S, Youtube
			if( file_exists($UpFilePath.$OneRec["fname1"].".mp3") )
				$OneRec["exist_file_1"] = 1;

			if ( $RBizType == 4 ) { // S2S
				if( file_exists($DownFilePath.$OneRec["fname1"].".mp3") )
					$OneRec["exist_file_2"] = 1;
			}
		}
		$TotRec[] = $OneRec;
		$cnt++;
		//$log->trace("ONE : \n".json_encode($OneRec));
	}
	
	//$log->trace("TOT : \n".json_encode($TotRec));
}
mysqli_close($DBCon);

$Response["data"] = $TotRec;

$log->trace("RES : \n".json_encode($Response));

if ( isset( $_POST['isAll'] ) ) $log->trace("isAll : ".$_POST['isAll']);
if ( isset( $_POST['svctype'] ) ) $log->trace("svctype : ".$_POST['svctype']);

if ( isset( $_POST['StartDate'] ) ) $log->trace("StartDate : ".$_POST['StartDate']);
if ( isset( $_POST['EndDate'] ) ) $log->trace("EndDate : ".$_POST['EndDate']);

if ( isset( $_POST['Status'] ) ) $log->trace("Status : ".$_POST['Status']);

if ( isset( $_POST['Check_Urgent'] ) ) $log->trace("Check_Urgent : ".$_POST['Check_Urgent']);
if ( isset( $_POST['Check_QPremium'] ) ) $log->trace("Check_QPremium : ".$_POST['Check_QPremium']);
if ( isset( $_POST['Check_Layout'] ) ) $log->trace("Check_Layout : ".$_POST['Check_Layout']);

print json_encode($Response);
?>
