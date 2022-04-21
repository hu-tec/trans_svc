<?
setlocale(LC_ALL,'ko_KR.UTF-8');
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('speech_proc_filesave');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$BizType = $_POST["BizType"];
	$JobName = $_POST["JobName"];
}
else  {
	$log->FATAL("비정상 접속");
	exit;
}

$TableName = "";
if ( $BizType == 2 ) $TableName = "STT";
else if ( $BizType == 3 ) $TableName = "VIDEO";
else if ( $BizType == 4 ) $TableName = "S2S";
else if ( $BizType == 5 ) $TableName = "YOUTUBE";

$log->trace("*************** ".$TableName." File Save  **************");
$log->INFO("*** Begin :: UserSeq=".$_SESSION['useridkey']);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);


$Response = array();
$ResText="";

$projectname="";
$trans_type=0;
$src_text="";
$tgt_text="";
$isOK = 1;

// project - DB Insert
$useridkey = $_SESSION['useridkey']; 
$svccode = $_SESSION['svccode'];

$sql = "SELECT hex(projectname) as projectname, trans_type, src_text, tgt_text FROM ".$TableName."_Job ";
$sql = $sql."where job_name = UNHEX('".$JobName."') and flag=0";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$projectname = strtolower($row['projectname']);
		$trans_type = (int)$row['trans_type'];
		$src_text = $row['src_text'];

		if ( $trans_type > 1 )
			$tgt_text = $row['tgt_text'];
		//$log->trace("src_text = [".$src_text."]");
	}
}

if ( $isOK == 1 ) {
	$SaveLink = $DownFilePath.$JobName;
	file_put_contents($SaveLink, $src_text);
	$log->trace(" JobName: ".$JobName." :: Create Text File : ".$SaveLink);

	if ( $trans_type > 2 ) {
		$SaveLink = $DownFilePath.$projectname;
		file_put_contents($SaveLink, $tgt_text);
		$log->trace(" ProjectName: ".$projectname." :: Create Text File : ".$SaveLink);
	}
}

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( strlen($ResText)>0 ) {
	$Response["RText"] = $ResText;
	$log->trace( $ResText );
}

print json_encode($Response);

$log->trace("RES : ".json_encode($Response));
?>
