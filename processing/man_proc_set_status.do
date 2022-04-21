<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;
require_once $include_mmsrc;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_set_status');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$useridkey   = $_SESSION['useridkey'];
	$svccode    = $_SESSION['svccode'];

	$SVCType     = $_POST["SVCType"];
	$ProjectName = $_POST['ProjectName'];
	$tmp_fname   = $_POST['JobName'];
	$jobid       = $_POST['JobId'];
	$New_Status  = $_POST['status'];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$TableName = "";
if ( $SVCType == 0 ) $TableName = "MMS";
else if ( $SVCType == 1 ) $TableName = "MT";
else if ( $SVCType == 2 ) $TableName = "STT";
else if ( $SVCType == 3 ) $TableName = "VIDEO";
else if ( $SVCType == 4 ) $TableName = "S2S";
else if ( $SVCType == 5 ) $TableName = "YOUTUBE";

$log->trace("********** ".$TableName." useridkey = ".$useridkey." **********");
$log->trace("ProjectName=".$ProjectName." tmp_fname=".$tmp_fname." jobid=".$jobid." New_Status=".$New_Status);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$isOK = 1;
$Response = array();
$UserType = 0;

$sql = "SELECT utype, grade FROM User where svccode=".$svccode." && useridkey=".$useridkey;
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}
if ( $isOK == 1 ) {
	if( ($row = mysqli_fetch_array($DBQRet)) ) {
		$UserType = (int)$row['utype'];
	}
}

if ( $isOK == 1 ) {
	if ( $UserType != 99 ) {
		$isOK = 0;
		$ResText = "비정상 접속";
		$log->ERROR($ResText);
	}
}

////////////////////////////////////////////////////////////
if ( $isOK == 1 ) {
	$sql = "UPDATE ".$TableName."_Job SET status=".$New_Status;
	if ( $SVCType == 0 ) 
		$sql = $sql." where flag=0 && tmp_fname = UNHEX('$tmp_fname') && jobid='$jobid'";
	else 
		$sql = $sql." where flag=0 && projectname = UNHEX('$ProjectName')";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
		$log->ERROR( $sql );
		$log->ERROR($ResText);
	}
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
