<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;
require_once $include_mmsrc;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('doc_proc_analysis');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$projectname = $_POST["projectname"];

	$Trans_Type      = $_POST["Trans_Type"];
	$Trans_Layout    = $_POST["Trans_Layout"];
	$Trans_QAPremium = $_POST["Trans_QAPremium"];
	$Trans_Urgent    = $_POST["Trans_Urgent"];

	$useridkey   = $_SESSION['useridkey'];
	$svccode     = $_SESSION['svccode'];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

/******************************************************************/
$log->trace("*** Begin :: projectname=".$projectname);

$Response = array();
$isOK = 1;
$ResText = "";
$isLogin=false;
$AssignHuman = 0;

if ( $Trans_Layout==1 || $Trans_QAPremium==1 || $Trans_Urgent==1 ) $AssignHuman = 1;

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

/************************ Memsource Login *********************/
if ( isset( $_SESSION['token'] ) ) {
	$log->trace("--- exist Login token ---\n".$_SESSION['token']);
	$isLogin = MMSrc_WhoAmI();
}
if ( $isLogin == false ) {
	if ( MMSrc_Login( 1 ) == false ) $isOK=0;
}
/******************** Analysis : PROJECT **********************/
if (  $isOK == 1 ) {
	$sql = "SELECT projectid, srcLang, tgtLang FROM MMS_Project where flag=0 and useridkey=".$useridkey." and svccode=".$svccode;
	$sql = $sql." and projectname = UNHEX('".$projectname."')";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
	}
	else {
		if ( $row = mysqli_fetch_array($DBQRet) ) {
			$srcLang = $row['srcLang'];
			$tgtLang = $row['tgtLang'];

			/* Step 1. Project 생성  */
			$ProjectUid = MMSrc_Create_Project($projectname, $srcLang, $tgtLang);
			$log->trace("Create Project UID = [".$ProjectUid."]");
			if ( strlen($ProjectUid) == 0 ) $isOK = 0;
			else {
				// update project db
				$sql = "UPDATE MMS_Project SET projectid = '".$ProjectUid."' where flag=0 and projectname = UNHEX('".$projectname."')";
				$log->trace( $sql );
				if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) $isOK = 0;
			}
		}
	}
}

$JobIDArray = array();
$JobNameArray = array();
$JobChkArray = array();

/******************** Analysis : JOB **********************/
if ( $isOK == 1 ) {
	$sql = "SELECT hex(MMS_Job.tmp_fname) as tmp_fname, ext_file, jobid, numoftu FROM MMS_Job where flag=0 and projectname = UNHEX('".$projectname."')";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
	}
	else {
		$log->trace(">>>>>>>>>>>>>>>>>>>>>>> DB_RowCount=".DB_RowCount($DBQRet) );
		while( $isOK==1 && ($row = mysqli_fetch_array($DBQRet)) ) {
			$tmp_fname  = strtolower($row['tmp_fname']);
			$JobNameArray[] = $tmp_fname;

			$ext_file   = $row['ext_file'];
			$uploadfile = $UpFilePath.$tmp_fname;

			/* Step 2. Job 생성  */
			$JobUid = MMSrc_Create_Job($ProjectUid, $tgtLang, $uploadfile, $tmp_fname, $ext_file);
			$log->trace( ">>>>>>>>>>>>>>>>>>>>>>> JobUid=".$JobUid );
			if ( strlen($JobUid) == 0 ) $isOK = 0;
			else {
				$JobIDArray[] = $JobUid;
				$JobChkArray[] = 0;
				// update job db
				$sql = "UPDATE MMS_Job SET status=1, jobid = '".$JobUid."'"; // status 1 - 작업 생성
				$sql = $sql." where flag=0 and projectname = UNHEX('".$projectname."') and tmp_fname = UNHEX('".$tmp_fname."')";
				$log->trace( $sql );
				if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) $isOK = 0;
			}
			$log->trace(">>>>>>>>>>>>>>>>>>>>>>> isOK=".$isOK );
		}
	}
}
if ( $isOK == 1 )
	mysqli_commit($DBCon);
else 
	mysqli_rollback($DBCon);

if ( $isOK == 0 ) $log->ERROR($ResText);
$Response["isOK"] = $isOK;
if ( strlen($ResText) > 0 ) $Response["RText"] = $ResText;
$log->trace("RES : ".json_encode($Response));

ob_start();

print json_encode($Response);

$size = ob_get_length();
$log->trace("RET SIZE : ".$size);
header("Content-Encoding: none");
header("Content-Length: $size");
header("Connection: close");

ob_end_flush();
ob_flush();
flush();
session_write_close();

$log->trace("=================================== Return ==================================");

$CheckCount = 0;
sleep( 10 );
////////////////////// 분석 /////////////////////////
while ( $isOK == 1 ) {
$log->trace("**************************************************** CheckCount=".$CheckCount." ********************************************************************");
	for($i = 0; $i < count($JobIDArray) && $isOK==1; $i++) {
		if ( $JobChkArray[$i] == 1 ) continue;
		
		/* Step 3. 문서 분석  */
		$AnalysisUid = MMSrc_getAnalysisUid($JobIDArray[$i]);
		$log->trace(">>>>>>>>>>>>>>>>>>>>>>>       JobID[".$i."]=".$JobIDArray[$i] );
		$log->trace(">>>>>>>>>>>>>>>>>>> JobNameArray[".$i."]=".$JobNameArray[$i] );
		$log->trace(">>>>>>>>>>>>>>>>>>>>>>> AnalysisUid=".$AnalysisUid );
		if ( strlen($AnalysisUid) == 0 ) $isOK = 0;
		else if ( $AnalysisUid == "JOB_NOT_READY" ) {}

		if ( $isOK == 1 && $AnalysisUid != "JOB_NOT_READY" ) {
			$ResAnalysis = MMSrc_resultAnalysis($JobIDArray[$i], $AnalysisUid);
			if ( strlen($AnalysisUid) == 0 ) $isOK = 0;
			else {
				$NumChar = $ResAnalysis->characters;
				$NumWord = $ResAnalysis->words;
				$NumSeg  = $ResAnalysis->segments;
				if ( $NumWord ) {
					$JobChkArray[$i] = 1;
					$CheckCount ++;
					// update job db
					$sql = "UPDATE MMS_Job SET status=2, jobid = '".$JobIDArray[$i]."'"; // status 2 - 분석 완료
					$sql = $sql." , numofchar=".(int)$NumChar.", numofword=".(int)$NumWord.", numoftu=".(int)$NumSeg;
					$sql = $sql." where projectname = UNHEX('".$projectname."') and tmp_fname = UNHEX('".$JobNameArray[$i]."')";
					$log->trace( $sql );
					if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) $isOK = 0;
				}
			}
		}
	}

	if ( $isOK==0 ) break;
	if ( count($JobIDArray) <= $CheckCount ) break;
	sleep( 5 );
}

if ( $isOK == 1 )
	mysqli_commit($DBCon);
else 
	mysqli_rollback($DBCon);
mysqli_close($DBCon);

$log->trace("***********************************************");

?>
