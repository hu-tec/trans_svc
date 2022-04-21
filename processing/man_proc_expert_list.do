<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_expert_list');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$Response = array();

$log->trace("*************** Expert List Query **************");

$isOK = 1;

// DB Query
$sql = "SELECT useridkey, userid, name, phone FROM User WHERE svccode=1 && ( utype=21 || utype=99 )  order by utype";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}

if ( $isOK == 1 ) {
	$TotRec = array();
	while($row = mysqli_fetch_array($DBQRet)) {
		$OneRec = array();
		$OneRec["useridkey"] = $row['useridkey'];
		$OneRec["userid"]    = $row['userid'];
		$OneRec["name"]      = $row['name'];
		$OneRec["phone"]     = $row['phone'];

		$TotRec[] = $OneRec;
		//$log->trace("ONE : \n".json_encode($OneRec));
	}
	
	//$log->trace("TOT : \n".json_encode($TotRec));
}
mysqli_close($DBCon);

if ( $isOK == 1 ) {
	$Response["isOK"]     = $isOK;
	$Response["ExpertList"] = $TotRec;
	$log->trace("RES : \n".json_encode($Response));
}

print json_encode($Response);

?>
