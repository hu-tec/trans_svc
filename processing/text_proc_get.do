<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('text_proc_get');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$useridkey   = $_SESSION['useridkey'];
	$svccode     = $_SESSION['svccode'];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("********** useridkey=".$useridkey." **********");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$isOK = 1;
$Response = array();
$SrcText = "";
$TgtText = "";

$sql = "SELECT src_text, tgt_text FROM MT_Job";
$sql = $sql." where flag=0 and status<=3";
$sql = $sql." and useridkey=".$_SESSION['useridkey']." and svccode=".$_SESSION['svccode'];
$sql = $sql." order by sdate desc limit 1";

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$SrcText = $row['src_text'];
		$TgtText = $row['tgt_text'];

		$Response["SrcText"] = $SrcText;
		$Response["TgtText"] = $TgtText;
	}
}

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
$log->trace("SEND Result : ".json_encode($Response));
print json_encode($Response);
?>