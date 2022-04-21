<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_alert_save');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$MType = (int)$_POST["MType"];
	$Content = $_POST["Content"];

	$Idx = -1;
	if ( isset( $_POST['Idx'] ) )
		$Idx = (int)$_POST['Idx'];

	$useridkey   = $_SESSION['useridkey'];
	$svccode     = $_SESSION['svccode'];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("********** useridkey=".$useridkey." **********");
$log->trace("MType : ".$MType." Content : ".$Content);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$isOK = 1;
$Response = array();

$Content = preg_replace("/\'/","\\'", $Content);

if ( $Idx == -1 ) {
	$sql = "INSERT INTO MBox (sdate, useridkey, svccode, mtype, message) VALUES (";
	$sql = $sql."now(), $useridkey, $svccode, $MType, '$Content')";
}
else {
	$sql = "UPDATE MBox SET sdate=now(), useridkey=".$useridkey.", mtype=".$MType.", message='".$Content."'";
	$sql = $sql." where flag=0 && svccode=".$svccode." && seq=".$Idx;
}
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $isOK == 1 ) mysqli_commit($DBCon);
else  mysqli_rollback($DBCon);
mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( $isOK == 0 ) $log->ERROR($ResText);
if ( strlen($ResText) > 0 ) $Response["RText"] = $ResText;

$log->trace("SEND Result : ".json_encode($Response));
print json_encode($Response);
?>