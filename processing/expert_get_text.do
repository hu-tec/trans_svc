<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('expert_get_text');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$expertid   = $_SESSION['useridkey'];
	$svccode    = $_SESSION['svccode'];
	$utype      = (int)$_SESSION['utype'];

	$svc_type = (int)$_POST["svc_type"];
	$ProjectName = $_POST['Project'];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("********** expert = ".$expertid." **********");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $svc_type == 1 ) $DB_Table_Name = "MT_Job";
else if ( $svc_type == 2 ) $DB_Table_Name = "STT_Job";
else if ( $svc_type == 3 ) $DB_Table_Name = "VIDEO_Job";
else if ( $svc_type == 4 ) $DB_Table_Name = "S2S_Job";
else if ( $svc_type == 5 ) $DB_Table_Name = "YOUTUBE_Job";

$isOK = 1;
$Response = array();
$SrcText = "";
$TgtText = "";
$trans_type = 0;

$sql = "SELECT trans_type, ai_api, srcLang, tgtLang, src_text, tgt_text,";

if ( $svc_type == 1 ) $sql = $sql." '0' as job_name,";
else $sql = $sql." LOWER(hex(job_name)) as job_name,";

$sql = $sql." (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang) as SrcLangText,";
$sql = $sql." (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = tgtLang) as TgtLangText";

$sql = $sql." FROM ".$DB_Table_Name;
$sql = $sql." where flag=0 && projectname=UNHEX('".$ProjectName."')";
if ( $utype == 21 )
	$sql = $sql." && expert_id=".$expertid;
$sql = $sql." && svccode=".$_SESSION['svccode'];
$sql = $sql." order by sdate desc limit 1";

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$trans_type = (int)$row['trans_type'];

		$Response["trans_type"]= $trans_type;
		$Response["job_name"]= $row['job_name'];
		$Response["SrcText"] = $row['src_text'];
		if ( $svc_type == 1 || $trans_type > 2 )
			$Response["TgtText"] = $row['tgt_text'];

		$Response["ai_api"]  = $row['ai_api'];
		$Response["srcLang"] = $row['srcLang'];
		$Response["SrcLangText"] = $row['SrcLangText'];
		$Response["tgtLang"] = $row['tgtLang'];
		$Response["TgtLangText"] = $row['TgtLangText'];
	}
}

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
$log->trace("SEND Result : ".json_encode($Response));
print json_encode($Response);
?>