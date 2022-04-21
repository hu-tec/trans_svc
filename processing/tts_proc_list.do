<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('tts_proc_list');

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
$TotRec = array();
$isOK = 1;
$ProjectName="";

$log->trace("*************** Information Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

/*if ( isset( $_SESSION['ProjectName'] ) ) {
	$ProjectName = $_SESSION['ProjectName'];
}
else {*/
	$sql = "SELECT hex(projectname) as projectname FROM MT_Job";
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
/*}*/

if ( $isOK == 1 ) {
	$log->INFO("*** UserSeq=".$_SESSION['useridkey'].", ProjectName=".$ProjectName);

	// DB Query
	$sql = "SELECT sdate, hex(projectname) as projectname,";
	$sql = $sql." (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = srcLang) as SrcLangText,";
	$sql = $sql." (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = tgtLang) as TgtLangText,";
	$sql = $sql." srcLang, tgtLang,";
	$sql = $sql." numofchar, cost, status,";
	$sql = $sql." hex(src_audio) as src_audio, hex(tgt_audio) as tgt_audio,";
	$sql = $sql." trans_type, qa_premium, urgent, expert_category, prediction_time";
	$sql = $sql." FROM MT_Job";
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

		$OneRec["seq"]         = $cnt;

		$OneRec["projectname"] = strtolower($row['projectname']);

		$OneRec["srcLang"]     = $row['srcLang'];
		$OneRec["tgtLang"]     = $row['tgtLang'];

		$OneRec["numofchar"]   = $row['numofchar'];

		$OneRec["cost"]        = $row['cost'];

		$OneRec["status"]      = $row['status'];

		$OneRec["src_audio"]      = strtolower($row['src_audio']);
		$OneRec["tgt_audio"]      = strtolower($row['tgt_audio']);

		$OneRec["trans_type"]      = $row['trans_type'];

		$OneRec["trans_quality"]   = $row['qa_premium'];
		$OneRec["urgent"]          = $row['urgent'];
		
		$OneRec["prediction_time"] = $row['prediction_time'];
		$OneRec["expert_category"] = $row['expert_category'];

		$OneRec["exist_file_1"] = 0;
		$OneRec["exist_file_2"] = 0;
		if( file_exists($DownFilePath.$OneRec["src_audio"].".mp3") )
			$OneRec["exist_file_1"] = 1;
		if( file_exists($DownFilePath.$OneRec["tgt_audio"].".mp3") )
			$OneRec["exist_file_2"] = 1;

		$OneRec["sdate"]     = $row['sdate'];

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
