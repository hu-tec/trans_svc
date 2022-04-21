<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;
require_once $include_google;
require_once $include_naver;
require_once $include_systran;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('expert_text_trans');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$expertid   = $_SESSION['useridkey'];
	$svccode    = $_SESSION['svccode'];
	$utype      = (int)$_SESSION['utype'];

	$MTCloud     = $_POST['MTCloud'];
	$svc_type    = (int)$_POST["svc_type"];
	$ProjectName = $_POST['Project'];
	$srcLang     = $_POST["srcLang"];
	$tgtLang     = $_POST["tgtLang"];
	$SrcArray    = $_POST["SrcArray"];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("********** expert = ".$expertid." **********");
$log->trace(" Project: ".$ProjectName);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $svc_type == 1 ) $DB_Table_Name = "MT";
else if ( $svc_type == 2 ) $DB_Table_Name = "STT";
else if ( $svc_type == 3 ) $DB_Table_Name = "VIDEO";
else if ( $svc_type == 4 ) $DB_Table_Name = "S2S";
else if ( $svc_type == 5 ) $DB_Table_Name = "YOUTUBE";

$isOK = 1;
$Response = array();
$Response["ErrorCode"] = "";
$isUpdate=0;

$sql = "SELECT count(*) as cnt FROM ".$DB_Table_Name."_PostEdit";
$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";
//$sql = $sql." && expert_id=".$expertid." && svccode=".$svccode;
$sql = $sql." && svccode=".$svccode;
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($sql);
	$log->ERROR($ResText);
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		if ( (int)$row['cnt'] != 0 ) $isUpdate = 1;
	}
}

if ( $isOK == 1 ) {
	if ( $isUpdate == 1 ) {
		$sql = "UPDATE ".$DB_Table_Name."_PostEdit SET flag=1";
		$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";
		// if ( $utype == 21 )
		// 	$sql = $sql." && expert_id=".$expertid;
		$sql = $sql." && svccode=".$svccode;
	
		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
			$isOK = 0;
			$log->ERROR($sql);
			$log->ERROR($ResText);
		}
	}
}

$All_Src_Text = "";
$Cnt = 0;
for($i=0; $i<count($SrcArray) && $isOK==1; $i++) {
	$SaveSrcText = preg_replace("/\'/","\\'", $SrcArray[$i]);
	if ( $Cnt > 0 )
		$All_Src_Text = $All_Src_Text."\r\n";
	$All_Src_Text = $All_Src_Text.$SaveSrcText;

	if ( $svc_type != 1 ) { // is not TTS
		// Source Sentence
		if ( $isUpdate == 0 ) {
			$sql = "INSERT INTO ".$DB_Table_Name."_PostEdit (projectname, expert_id, svccode, sdate, lang, seq, text_one) VALUES (";
			$sql = $sql."UNHEX('$ProjectName'), $expertid, $svccode, now(), '$srcLang', $i, '$SaveSrcText')";
		}
		else {
			$sql = "UPDATE ".$DB_Table_Name."_PostEdit SET flag=0, sdate=now(), text_one='".$SaveSrcText."'";
			$sql = $sql." where projectname = UNHEX('".$ProjectName."')";
			//$sql = $sql." && expert_id=".$expertid." && svccode=".$svccode." && lang='".$srcLang."' && seq=".$i;
			$sql = $sql." && svccode=".$svccode." && lang='".$srcLang."' && seq=".$i;
		}
		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) $isOK = 0;
	}
	if ( $isOK == 0 ) continue;

	////////////////////////////////////////////////////////////
	if ( $MTCloud == "01") // Google
		$Ext_TransAPI_Response = GOOGLE_Translate( [$SrcArray[$i]], $tgtLang );
	else if ( $MTCloud == "02") // Naver
		$Ext_TransAPI_Response = NAVER_Translate( $srcLang, $SrcArray[$i], $tgtLang );
	else if ( $MTCloud == "04") // SYSTRAN
		$Ext_TransAPI_Response = SYSTRAN_Translate( $srcLang, $SrcArray[$i], $tgtLang );
	////////////////////////////////////////////////////////////
	$log->trace("Src:[".$srcLang."][".$SaveSrcText."]");
	if ( $Ext_TransAPI_Response["isOK"] == 1 ) {
		$One_Tgt_Text = $Ext_TransAPI_Response["Target_Text"];
		$log->trace("Tgt:[".$tgtLang."][".$One_Tgt_Text."]");

		if ( $svc_type == 1 ) { // TTS
			if ( $isUpdate == 0 ) {
				$sql = "INSERT INTO ".$DB_Table_Name."_PostEdit (projectname, expert_id, svccode, sdate, seq, src_text_one, tgt_text_one) VALUES (";
				$sql = $sql."UNHEX('$ProjectName'), $expertid, $svccode, now(), $i, '$SaveSrcText', '$One_Tgt_Text')";
			}
			else {
				$sql = "UPDATE ".$DB_Table_Name."_PostEdit SET flag=0, sdate=now()";
				$sql = $sql." , src_text_one='".$SaveSrcText."', tgt_text_one='".$One_Tgt_Text."'";
				$sql = $sql." where projectname = UNHEX('".$ProjectName."')";
				//$sql = $sql." && expert_id=".$expertid." && svccode=".$_SESSION['svccode']." && seq=".$i;
				$sql = $sql." && svccode=".$_SESSION['svccode']." && seq=".$i;
			}
		}
		else { // is not TTS
			// Target Sentence
			if ( $isUpdate == 0 ) {
				$sql = "INSERT INTO ".$DB_Table_Name."_PostEdit (projectname, expert_id, svccode, sdate, lang, seq, text_one) VALUES (";
				$sql = $sql."UNHEX('$ProjectName'), $expertid, $svccode, now(), '$tgtLang', $i, '$One_Tgt_Text')";
			}
			else {
				$sql = "UPDATE ".$DB_Table_Name."_PostEdit SET flag=0, sdate=now(), text_one='".$One_Tgt_Text."'";
				$sql = $sql." where projectname = UNHEX('".$ProjectName."')";
				//$sql = $sql." && expert_id=".$expertid." && svccode=".$svccode." && lang='".$tgtLang."' && seq=".$i;
				$sql = $sql." && svccode=".$svccode." && lang='".$tgtLang."' && seq=".$i;
			}
		}
		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) $isOK = 0;
	}
	else {
		$isOK = 0;
		if ( $MTCloud == "01") { // Google
			$ResText = "Google AI번역을 수행하지 못하였습니다. 관리자에게 연락 바랍니다.";
			$log->ERROR("Google Trans ErrorMsg:".$Ext_TransAPI_Response["ErrorMsg"] );
		}
		else if ( $MTCloud == "02") { // Naver
			$Response["ErrorCode"] = $Ext_TransAPI_Response["ErrorCode"]; // N2MT02-지원하지 않는 source 언어, N2MT04-지원하지 않는 target 언어
			$ResText = $Ext_TransAPI_Response["ErrorMsg"];
			$log->ERROR("Naver Trans ErrorCode:".$Ext_TransAPI_Response["ErrorCode"].", ErrorMsg:".$Ext_TransAPI_Response["ErrorMsg"] );
		}
		else if ( $MTCloud == "04") { // SYSTRAN
			$Response["ErrorCode"] = $Ext_TransAPI_Response["ErrorCode"];
			$ResText = $Ext_TransAPI_Response["ErrorMsg"];
			$log->ERROR("SYSTRAN Trans ErrorCode:".$Ext_TransAPI_Response["ErrorCode"].", ErrorMsg:".$Ext_TransAPI_Response["ErrorMsg"] );
		}
	}
	////////////////////////////////////////////////////////////
}
if ( $isOK == 1 ) { // Update MT Cloud Code
	$sql = "UPDATE ".$DB_Table_Name."_Job SET ai_api='".$MTCloud."', src_text='".$All_Src_Text."'";
	//$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."') && expert_id=".$expertid;
	$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) $isOK = 0;
}

if ( $isOK == 1 ) mysqli_commit($DBCon);
else  mysqli_rollback($DBCon);

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( strlen($ResText) > 0 )
	$Response["RText"] = $ResText;

$log->trace("SEND Result : ".json_encode($Response));
print json_encode($Response);
?>
