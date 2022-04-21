<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_reset_user');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$useridkey = $_SESSION['useridkey'];
	$svccode   = $_SESSION['svccode'];

	$Uidx  = $_POST["Uidx"];
	$EMail = $_POST["EMail"];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$ResText = "";
$log->trace("********** User flag reset : useridkey = ".$useridkey." **********");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$isOK = 1;
$Response = array();

$sql = "UPDATE User SET flag=0";
$sql = $sql." WHERE flag=1 && svccode=".$svccode." && useridkey=".$Uidx." && userid='".$EMail."'";

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR( $sql );
	$log->ERROR($ResText);
}

////////////////////////////////////////////////////////////

if ( $isOK == 1 ) mysqli_commit($DBCon);
else  mysqli_rollback($DBCon);

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( strlen($ResText) > 0 )
	$Response["RText"] = $ResText;

$log->trace("SEND Result : ".json_encode($Response));
print json_encode($Response);
?>
