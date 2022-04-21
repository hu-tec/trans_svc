<?
setlocale(LC_ALL,'ko_KR.UTF-8');
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('youtube_proc_save_info');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$SrcLang = $_POST["SrcLang"];
	$TgtLang = $_POST["TgtLang"];
	$ori_fname = $_POST["ori_fname"];
	$duration = (int)$_POST["duration"];
	$ori_URL = $_POST["ori_URL"];
	$down_URL = $_POST["down_URL"];
}
else  {
	$log->FATAL("비정상 접속");
	exit;
}

$useridkey = $_SESSION['useridkey']; 
$svccode = $_SESSION['svccode'];

$log->trace("*************** Save First YOUTUBE Info **************");
$log->INFO("*** Begin :: UserSeq=".$_SESSION['useridkey'].", SrcLang=".$SrcLang.", TgtLang:".$TgtLang.", URL:".$ori_URL);

$Response = array();
$ResText="";
$isOK = 1;

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

// Check previous Request
$sql = "SELECT count(*) as cnt FROM YOUTUBE_Job";
$sql = $sql." where flag=0 && status<3 && useridkey=".$useridkey." && svccode=".$svccode;
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		if ( (int)$row['cnt'] > 0 ) {
			$ResText = "진행 중인 건이 있습니다. 삭제 또는 결제 후 진행하여 주십시오.";
			$isOK = 0;
		}
	}
	else {
		$log->ERROR( $sql );
		$ResText = "요청 건을 조회할 수 없습니다.";
		$isOK = 0;
	}
}

////////////////////////////////////////////////////////////////
if ( $isOK == 1 ) {
	// project - DB Insert
	$ProjectName = exec('uuidgen');
	$ProjectName = strtolower(str_replace('-', '', $ProjectName));

	if (class_exists('Normalizer')) {
		if (Normalizer::isNormalized($ori_fname, Normalizer::FORM_D))
			$ori_fname = Normalizer::normalize($ori_fname, Normalizer::FORM_C);
	}

	$sql = "INSERT INTO YOUTUBE_Job (sdate, useridkey, svccode, projectname, ori_URL, down_URL, ori_fname, srcLang, tgtLang, duration, status) VALUES (";
	$sql = $sql."now(), $useridkey, $svccode, UNHEX('$ProjectName'), '$ori_URL', '$down_URL', '$ori_fname', '$SrcLang', '$TgtLang', $duration, 2)";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) $isOK = 0;
}

if ( $isOK == 1 ) {
	$_SESSION['ProjectName'] = strtolower($ProjectName);
	$ResText = "정보 저장 완료";
	mysqli_commit($DBCon);
}
else 
	mysqli_rollback($DBCon);
mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( strlen($ResText)>0 ) {
	$Response["RText"] = $ResText;
	$log->trace( $ResText );
}

print json_encode($Response);

$log->trace("RES : ".json_encode($Response));

?>
