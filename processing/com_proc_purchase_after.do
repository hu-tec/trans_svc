<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('com_proc_purchase_after');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$BizType        = (int)$_POST["BizType"];
	$Trans_Type     = (int)$_POST["Trans_Type"];
	$AI_UType       = (int)$_POST["AI_UType"];
	$Layout         = (int)$_POST["Layout"];
	$Urgent         = (int)$_POST["Urgent"];
	$Trans_Quality  = (int)$_POST["QPremium"];
	$ExpertCategory = $_POST["ExpertCategory"];
	$TotalCost      = (int)$_POST["TotalCost"];
	$PredictionTime = (int)$_POST["PredictionTime"];
	$PTypeVal       = (int)$_POST["PTypeVal"];
} 
else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("BizType = ".$BizType );
$log->trace("Trans_Type = ".$Trans_Type );
$log->trace("Layout = ".$Layout );
$log->trace("Urgent = ".$Urgent );
$log->trace("Trans_Quality = ".$Trans_Quality );
$log->trace("ExpertCategory = ".$ExpertCategory );
$log->trace("TotalCost = ".$TotalCost );
$log->trace("PredictionTime = ".$PredictionTime );
$log->trace("PTypeVal = ".$PTypeVal );

$isOK = 1;
$Response = array();

$projectid="";

$ProjectName = strtolower($_SESSION['ProjectName']);
$useridkey = $_SESSION['useridkey'];
$svccode = $_SESSION['svccode'];
$point = $_SESSION['point'];

$remain_point = $point;
$Response["point"] = $remain_point;

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

// Check remain Point
if ( $PTypeVal == 1 ) {
	if ( $point < $TotalCost ) {
		$ResText = "포인트가 부족합니다. 충전하신 후 결제 바랍니다.";
		$isOK = 0;
	}
}

if ( $BizType == 0 ) { // DOC
	//////////////////////////////////////////////////////////////////////////////
	// Find Project ID
	if ( $isOK == 1 ) { 
		$sql = "SELECT projectid FROM MMS_Project";
		$sql = $sql." where flag=0 and useridkey=".$useridkey." and svccode=".$svccode." and projectname=UNHEX('".$ProjectName."')";
		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
			$isOK = 0;
		}
		else {
			if ( $row = mysqli_fetch_array($DBQRet) ) {
				$projectid = $row['projectid'];
			}
			else {
				$log->ERROR( $sql );
				$ResText = "요청 건을 조회할 수 없습니다.";
				$isOK = 0;
			}
		}
	}
}

/////////// Change Point ///////////////////////////////////////
if ( $isOK == 1 ) {
	if ( $PTypeVal == 1 ) {
		$remain_point = $point - $TotalCost;
		$Response["point"] = $remain_point;
		$MCost = -$TotalCost;

		$sql = "INSERT INTO Point (useridkey, svccode, sdate, point, before_point, amount) VALUES (";
		$sql = $sql.$useridkey.", ".$svccode.", now(), ".$remain_point.", ".$point.", ".$MCost.")";

		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
			$log->ERROR( $sql );
			$ResText = "포인트 정보를 저장하지 못하였습니다.";
			$isOK = 0;
		}
	}
}

///////////////////// Purchase Table /////////////////////////////
// Check Exist 
$isIns=1;
if ( $isOK == 1 ) {
	$sql = "SELECT count(*) as cnt FROM Purchase";
	$sql = $sql." where flag=0 and useridkey=".$useridkey." and svccode=".$svccode." and goods_key=UNHEX('".$ProjectName."')";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
	}
	else {
		if ( $row = mysqli_fetch_array($DBQRet) ) {
			if ( (int)$row['cnt'] > 0 ) $isIns = 0;
		}
		else {
			$log->ERROR( $sql );
			$ResText = "요청 건을 조회할 수 없습니다.";
			$isOK = 0;
		}
	}
}

// Insert or Update : Purchase table
if ( $isOK == 1 && $isIns == 1 ) { //Insert
	$sql = "INSERT INTO Purchase (useridkey, svccode, sdate, goods_key, goods_id, trans_type, ai_utype, layout,";
	$sql = $sql." qa_premium, urgent, expert_category, cost, prediction_time, pay_status, pg_case) VALUES (";
	$sql = $sql.$useridkey.", ".$svccode.", now(), UNHEX('".$ProjectName."'), '".$projectid."', ".$Trans_Type.", ".$AI_UType.", ".$Layout;
	$sql = $sql.", ".$Trans_Quality.", ".$Urgent.", '".$ExpertCategory."', ".$TotalCost.", ".$PredictionTime.", 1, ".$PTypeVal.")";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) $isOK = 0;
}
else if ( $isOK == 1 && $isIns == 0 ) { // Update
	$sql = "UPDATE Purchase SET trans_type=".$Trans_Type.", ai_utype=".$AI_UType.", layout=".$Layout.", qa_premium=".$Trans_Quality.", urgent=".$Urgent;
	$sql = $sql.", expert_category='".$ExpertCategory."', cost=".$TotalCost.", prediction_time=".$PredictionTime." pay_status=1, pg_case=".$PTypeVal;
	$sql = $sql." where flag=0 and useridkey=".$useridkey." and svccode=".$svccode." and goods_key=UNHEX('".$ProjectName."') and goods_id='".$projectid."'";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) $isOK = 0;
}

///////////////////// Job Table /////////////////////////////////////////////////////////
if ( $isOK == 1  ) {
	$TableName = "";
	if ( $BizType == 0 ) $TableName = "MMS_Job";
	else if ( $BizType == 1 ) $TableName = "MT_Job";
	else if ( $BizType == 2 ) $TableName = "STT_Job";
	else if ( $BizType == 3 ) $TableName = "VIDEO_Job";
	else if ( $BizType == 4 ) $TableName = "S2S_Job";
	else if ( $BizType == 5 ) $TableName = "YOUTUBE_Job";

	if ( 0<=$BizType && $BizType<=5 ) {
		$sql = "UPDATE ".$TableName." SET status=3, expert_category='".$ExpertCategory."'"; // status 3 - 결제완료
		$sql = $sql." where flag=0 and projectname = UNHEX('".$ProjectName."')";

		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
			$log->ERROR( $sql );
			$ResText = "작업 정보를 저장하지 못하였습니다.";
			$isOK = 0;
		}
	}
	else {
		$ResText = "서비스를 구분할 수 없습니다.";
		$isOK = 0;
	}
}

if ( $isOK == 1 ) {
	mysqli_commit($DBCon);
	$_SESSION["point"] = $remain_point;
}
else 
	mysqli_rollback($DBCon);

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( $isOK == 0 ) $log->ERROR($ResText);
if ( strlen($ResText) > 0 ) $Response["RText"] = $ResText;
$log->trace("RES : ".json_encode($Response));

print json_encode($Response);

if ( $isOK == 1 ) {
	$BG_PROC_Name = "";
	if ( $BizType == 0 ) $BG_PROC_Name = "doc_proc_bg_trans";
	else if ( $BizType == 1 ) $BG_PROC_Name = "tts_proc_bg_create_tts";
	else if ( 2<=$BizType && $BizType<=4 ) $BG_PROC_Name = "speech_proc_bg_create_txt";
	else if ( $BizType == 5 ) $BG_PROC_Name = "youtube_proc_bg_batch"; // Down > speech_proc_bg_analysis > speech_proc_bg_create_txt

	if ( 0<=$BizType && $BizType<=5 ) {
		$log->trace("CAll Begin ".$BG_PROC_Name." BizType=".$BizType." ProjectName=".$ProjectName);
		shell_exec("php ".$BG_PROC_Name.".do ".$BizType." ".$ProjectName." > /dev/null 2>/dev/null &"); 
		$log->trace("CAll End ".$BG_PROC_Name." BizType=".$BizType." ProjectName=".$ProjectName);
	}
}
?>
