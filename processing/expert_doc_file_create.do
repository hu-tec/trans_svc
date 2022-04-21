<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;
require_once $include_mmsrc;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('expert_doc_file_create');

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
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("********** expert = ".$expertid." **********");
$log->trace("ProjectName=".$ProjectName." tmp_fname=".$tmp_fname." jobid=".$jobid);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$isOK = 1;
$Response = array();

if ( MMSrc_Login( 0 ) == false ) {
	$log->ERROR($Response["RText"]);
	exit;
}

////////////////// Get projectid //////////////////////////////////////////
if ( $isOK == 1 ) {
	$sql = "SELECT projectid";
	$sql = $sql." FROM MMS_Project";
	$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR( $sql );
		$log->ERROR($ResText);
	}
	else {
		if ( $row = mysqli_fetch_array($DBQRet) ) {
			$ProjectUid = $row['projectid'];
			$log->trace( "BEGIN >>>> PRJNAME : ".$ProjectName. "  ProjectUid : ".$ProjectUid );
		}
		else {
			$isOK = 0;
			$log->trace( "Not Found Record - Project : ".$ProjectName);
		}
	}
}

////////////////////////////////////////////////////////////
if ( $isOK == 1 ) {
	$CheckDN = 0;
	$MMS_Status = "";
	while ( $isOK == 1 ) {
		$MMS_Status = MMSrc_Job_Status(0, $ProjectUid, $jobid);
		$log->trace( "MMSrc_Job_Status : ".$MMS_Status);
		if ( strlen($MMS_Status) == 0 ) {
			$isOK = 0;
			$log->ERROR($Response["RText"]);
		}
		if ( $isOK == 1 && $MMS_Status == "COMPLETED" ) { 
			$DownFile = $DownFilePath.$tmp_fname;
			$Ret = MMSrc_FileDownload(0, $ProjectUid, $jobid, $DownFile);
			$log->trace( "MMSrc_FileDownload : ".$Ret);
			if ( strlen($Ret) == 0 ) {
				$isOK = 0;
				$log->ERROR($Response["RText"]);
			}
			else if ( $Ret == "OK" ) {
				if ($isOK == 1) $log->trace("파일 저장 ID=".$jobid);
				$CheckDN = 1;
			}
		}

		if ( $isOK==0 ) break;
		if ( $CheckDN == 1 ) break;
		sleep( 5 );
	}
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
