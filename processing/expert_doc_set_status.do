<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('expert_doc_set_status');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$expertid   = $_SESSION['useridkey'];
	$svccode    = $_SESSION['svccode'];

	$ProjectName = $_POST['Project'];
	$tmp_fname   = $_POST['JobName'];
	$jobid       = $_POST['JobId'];
	$New_Status  = $_POST['status'];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("********** expert = ".$expertid." **********");
$log->trace("ProjectName=".$ProjectName." tmp_fname=".$tmp_fname." jobid=".$jobid." New_Status=".$New_Status);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$isOK = 1;
$Response = array();

////////////////////////////////////////////////////////////
if ( $isOK == 1 ) {
	$sql = "UPDATE MMS_Job SET status=".$New_Status;
	//$sql = $sql." where flag=0 && tmp_fname = UNHEX('".$tmp_fname."') && jobid = '".$jobid."' && expert_id=".$expertid;
	$sql = $sql." where flag=0 && tmp_fname = UNHEX('".$tmp_fname."') && jobid = '".$jobid."'";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($sql);
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
