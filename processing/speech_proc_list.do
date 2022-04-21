<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('speech_proc_list');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$BizType = $_POST["BizType"];
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$TableName = "";
if ( $BizType == 2 ) $TableName = "STT";
else if ( $BizType == 3 ) $TableName = "VIDEO";
else if ( $BizType == 4 ) $TableName = "S2S";
else if ( $BizType == 5 ) $TableName = "YOUTUBE";

$log->trace("*************** ".$TableName." List Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$useridkey = $_SESSION['useridkey'];
$svccode   = $_SESSION['svccode'];

$Response = array();
$TotRec = array();
$isOK = 1;
$ProjectName="";

$sql = "SELECT hex(projectname) as projectname FROM ".$TableName."_Job";
$sql = $sql." where flag=0 and status<3";
$sql = $sql." and useridkey=".$_SESSION['useridkey']." and svccode=".$_SESSION['svccode'];
$sql = $sql." order by sdate desc limit 1";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$ProjectName = strtolower($row['projectname']);
		$_SESSION['ProjectName'] = $ProjectName;
		$log->trace( "PRJNAME Get From DB : ".$ProjectName );
	}
	else $isOK = 0;
}

if ( $isOK == 1 ) {
	$log->INFO("*** UserSeq=".$_SESSION['useridkey'].", ProjectName=".$ProjectName);

	// DB Query
	$sql = "SELECT sdate, hex(projectname) as projectname, if(isnull(job_name), '', hex(job_name)) as job_name,";
	$sql = $sql." ori_fname,";
	$sql = $sql." if(isnull(srcLang), '', srcLang) as srcLang,";
	$sql = $sql." if(isnull(tgtLang), '', tgtLang) as tgtLang,";
	$sql = $sql." duration, cost, status,";
	$sql = $sql." trans_type, qa_premium, urgent, expert_category, prediction_time";
	$sql = $sql." FROM ".$TableName."_Job";
	$sql = $sql." where flag=0 and status<3 and useridkey=".$_SESSION['useridkey']." and svccode=".$_SESSION['svccode'];
	$sql = $sql." and projectname = UNHEX('".$ProjectName."')";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}
}

if ( $isOK == 1 ) {
	$cnt=1;
	while($row = mysqli_fetch_array($DBQRet)) {
		$OneRec = array();

		$OneRec["seq"] = $cnt;
		$OneRec["sdate"] = $row['sdate'];

		$OneRec["projectname"] = strtolower($row['projectname']);
		$OneRec["job_name"] = strtolower($row['job_name']);

		$OneRec["ori_fname"] = $row['ori_fname'];
		if (class_exists('Normalizer')) {
			if (Normalizer::isNormalized($OneRec["ori_fname"], Normalizer::FORM_D))
				$OneRec["ori_fname"]= Normalizer::normalize($OneRec["ori_fname"], Normalizer::FORM_C);
		}	

		$OneRec["srcLang"] = $row['srcLang'];
		$OneRec["tgtLang"] = $row['tgtLang'];

		$OneRec["duration"] = $row['duration'];
		$OneRec["cost"]     = $row['cost'];
		$OneRec["status"]   = $row['status'];

		$OneRec["trans_type"]      = $row['trans_type'];
		$OneRec["qa_premium"]      = $row['qa_premium'];
		$OneRec["urgent"]          = $row['urgent'];
		$OneRec["expert_category"] = $row['expert_category'];
		$OneRec["prediction_time"] = $row['prediction_time'];

		$OneRec["exist_file"] = 0;
		if( file_exists($UpFilePath.$OneRec["job_name"]) )
			$OneRec["exist_file"] = 1;

		$TotRec[] = $OneRec;
		$cnt++;
		//$log->trace("ONE : \n".json_encode($OneRec));
	}
	
	//$log->trace("TOT : \n".json_encode($TotRec));
}
mysqli_close($DBCon);

$Response["data"] = $TotRec;

$log->trace("RES : \n".json_encode($Response));

print json_encode($Response);
?>
