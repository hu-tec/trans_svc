<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('user_proc_sum');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$useridkey = $_SESSION['useridkey'];
$svccode   = $_SESSION['svccode'];

$Response = array();
$isOK = 1;

$log->trace("*************** Information Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $isOK == 1 ) {
	$log->INFO("*** UserSeq=".$_SESSION['useridkey']);

	$sql = "select sum(total) as total, sum(complete) as complete, sum(ongoing) as ongoing FROM (";
	$sql = $sql." SELECT * FROM (";
	$sql = $sql."  (SELECT count(*) as total FROM MMS_Job, MMS_Project where MMS_Job.flag=0 && MMS_Project.projectname=MMS_Job.projectname && MMS_Project.useridkey=".$useridkey." && MMS_Project.svccode=".$svccode." ) A,";
	$sql = $sql."  (SELECT count(*) as complete FROM MMS_Job, MMS_Project where MMS_Job.flag=0 && MMS_Project.projectname=MMS_Job.projectname && MMS_Project.useridkey=".$useridkey." && MMS_Project.svccode=".$svccode."  && status=100) B,";
	$sql = $sql."  (SELECT count(*) as ongoing FROM MMS_Job, MMS_Project where MMS_Job.flag=0 && MMS_Project.projectname=MMS_Job.projectname && MMS_Project.useridkey=".$useridkey." && MMS_Project.svccode=".$svccode."  && status<100) C)";
	
	$sql = $sql." UNION ALL";
	$sql = $sql." SELECT * FROM (";
	$sql = $sql."  (SELECT count(*) as total FROM MT_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode.") A,";
	$sql = $sql."  (SELECT count(*) as complete FROM MT_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status=100) B,";
	$sql = $sql."  (SELECT count(*) as ongoing FROM MT_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status<100) C)";

	$sql = $sql." UNION ALL";
	$sql = $sql." SELECT * FROM (";
	$sql = $sql."  (SELECT count(*) as total FROM STT_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode.") A,";
	$sql = $sql."  (SELECT count(*) as complete FROM STT_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status=100) B,";
	$sql = $sql."  (SELECT count(*) as ongoing FROM STT_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status<100) C)";

	$sql = $sql." UNION ALL";
	$sql = $sql." SELECT * FROM (";
	$sql = $sql."  (SELECT count(*) as total FROM VIDEO_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode.") A,";
	$sql = $sql."  (SELECT count(*) as complete FROM VIDEO_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status=100) B,";
	$sql = $sql."  (SELECT count(*) as ongoing FROM VIDEO_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status<100) C)";

	$sql = $sql." UNION ALL";
	$sql = $sql." SELECT * FROM (";
	$sql = $sql."  (SELECT count(*) as total FROM S2S_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode.") A,";
	$sql = $sql."  (SELECT count(*) as complete FROM S2S_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status=100) B,";
	$sql = $sql."  (SELECT count(*) as ongoing FROM S2S_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status<100) C)";

	$sql = $sql." UNION ALL";
	$sql = $sql." SELECT * FROM (";
	$sql = $sql."  (SELECT count(*) as total FROM YOUTUBE_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode.") A,";
	$sql = $sql."  (SELECT count(*) as complete FROM YOUTUBE_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status=100) B,";
	$sql = $sql."  (SELECT count(*) as ongoing FROM YOUTUBE_Job where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status<100) C)";

	$sql = $sql.") T";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$log->ERROR( $sql );
		$isOK = 0;
	}
	else {
		if ( $row = mysqli_fetch_array($DBQRet) ) {
			$Response["TotalCount"]    = $row['total'];
			$Response["CompleteCount"] = $row['complete'];
			$Response["OngoingCount"]  = $row['ongoing'];
		}
		else {
			$log->ERROR( $sql );
			$ResText = "요청 건을 조회할 수 없습니다.";
			$isOK = 0;
		}
	}
}

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( $isOK == 0 ) $log->ERROR($ResText);
if ( strlen($ResText) > 0 ) $Response["RText"] = $ResText;

$log->trace("RES : \n".json_encode($Response));

print json_encode($Response);
?>
