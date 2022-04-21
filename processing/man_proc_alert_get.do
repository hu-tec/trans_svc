<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_alert_get');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

$SelectedMenu = 0;
if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$Idx = $_POST['Idx'];

	$useridkey   = $_SESSION['useridkey'];
	$svccode     = $_SESSION['svccode'];
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$Response = array();
$isOK = 1;

$log->trace("*************** Manager : Alert One Get Query **************");
$log->trace("Idx : ".$Idx);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$sql = "SELECT mtype, message";
$sql = $sql." FROM MBox";
$sql = $sql." WHERE svccode=".$svccode." && seq=".$Idx;

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}

if ( $isOK == 1 ) {
	if ($row = mysqli_fetch_array($DBQRet)) {
		$Response["mtype"] = $row['mtype'];
		$Response["message"] = $row['message'];
	}	
}
mysqli_close($DBCon);
$Response["isOK"] = $isOK;
if ( $isOK == 0 ) $log->ERROR($ResText);
if ( strlen($ResText) > 0 ) $Response["RText"] = $ResText;

$log->trace("RES : \n".json_encode($Response));

print json_encode($Response);
?>
