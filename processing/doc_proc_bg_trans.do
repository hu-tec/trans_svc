<?
require_once 'include.do';
require_once $include_db;
require_once $include_mmsrc;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('doc_proc_bg_trans');

$ProjectName = $argv[2];

$Response = array();
$isOK = 1;

$Token = "";

$ProjectUid = "";
$srcLang = "";
$tgtLang = "";

$JobIDArray = array();
$JobNameArray = array();

$JobUid = "";
$Trans_Type      = 0;
$Trans_Layout    = 0;
$Trans_QAPremium = 0;
$Trans_Urgent    = 0;

$AssignHuman = 0;

if ( strlen($ProjectName) < 1 ) {
    $log->fatal("비정상 접속");
	exit;
}

if ( MMSrc_Login( 0 ) == false ) {
	$log->ERROR($Response["RText"]);
	exit;
}
else $Token = $Response['token'];

if ( !DB_Connect($DBCon, $ResText) ) {
	$log->ERROR("DB Connect FAIL");
	exit;
}

/* Get Language :  Source / Target */
$sql = "SELECT projectid, srcLang, tgtLang";
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
		$srcLang = $row['srcLang'];
		$tgtLang = $row['tgtLang'];

		$log->trace( "BEGIN >>>> PRJNAME : ".$ProjectName. "ProjectUid : ".$ProjectUid." srcLang: ".$srcLang. " tgtLang: ".$tgtLang );
	}
	else {
		$isOK = 0;
		$log->trace( "Not Found Record - Project : ".$ProjectName);
	}
}

/* Get Job Records */
if ( $isOK == 1 ) {
	$sql = "SELECT hex(MMS_Job.tmp_fname) as tmp_fname, jobid, trans_type, layout, qa_premium, urgent";
	$sql = $sql." FROM MMS_Job";
	$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR( $sql );
		$log->ERROR($ResText);
	}
}

if ( $isOK == 1 ) {
	while($row = mysqli_fetch_array($DBQRet)) {
		$tmp_fname       = strtolower($row['tmp_fname']);
		$JobUid          = $row['jobid'];
		$Trans_Type      = (int)$row['trans_type'];
		$Trans_Layout    = (int)$row['layout'];
		$Trans_QAPremium = (int)$row['qa_premium'];
		$Trans_Urgent    = (int)$row['urgent'];

		$AssignHuman = 0;
		if ( $Trans_Layout==1 || $Trans_QAPremium==1 || $Trans_Urgent==1 ) $AssignHuman = 1;

		$JobNameArray[] = $tmp_fname;
		$JobIDArray[]   = $JobUid;

		/* Step 4. 문서 번역  */
		if ( MMSrc_Translation(0, $ProjectUid, $JobUid) == false ) {
			$isOK = 0;
			$log->ERROR($Response["RText"]);
		}
		else {
			$sql = "UPDATE MMS_Job SET status=11"; // status 11 - AI번역 중
			$sql = $sql." where flag=0 and projectname = UNHEX('".$ProjectName."') and tmp_fname = UNHEX('".$tmp_fname."')";
			$log->trace( $sql );
			if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
				$isOK = 0;
				$log->ERROR( $sql );
				$log->ERROR($ResText);
			}
		}
		if ( $isOK == 0 ) break;
	}
}

if ( $isOK == 1 )
	mysqli_commit($DBCon);
else 
	mysqli_rollback($DBCon);

/************************************************************************************/
//$SleepTime = (int)(10/count($JobIDArray))+1;
// Trans_Type -> 2:MT    3 : MT+Human   4: Human Translation
////////////////////// 번역 완료 확인, 파일 다운로드 /////////////////////////
$FState=100;
if ( ($Trans_Type == 2 && $AssignHuman == 1) || $Trans_Type == 3 || $Trans_Type == 4 ) $FState=50;

$CheckCount = 0;
$Status = "";
if ( $Trans_Type == 2 && $AssignHuman == 0 ) { // Only MT
	sleep( 10 );
	while ( $isOK == 1 ) {
		for($i = 0; $i < count($JobIDArray) && $isOK==1; $i++) {
			$Status = MMSrc_Job_Status(0, $ProjectUid, $JobIDArray[$i]);
			if ( strlen($Status) == 0 ) {
				$isOK = 0;
				$log->ERROR($Response["RText"]);
			}

			if ( $isOK == 1 && $Status == "COMPLETED" ) { 
				$DownFile = $DownFilePath.$JobNameArray[$i];
				$Ret = MMSrc_FileDownload(0, $ProjectUid, $JobIDArray[$i], $DownFile);
				if ( strlen($Ret) == 0 ) {
					$isOK = 0;
					$log->ERROR($Response["RText"]);
				}
				else if ( $Ret == "OK" ) {
					if ($isOK == 1) $log->trace( $i."번째 파일 저장"." ID=".$JobIDArray[$i]);
					$CheckCount++;
				}
			}
		}
		if ( $isOK==0 ) break;
		if ( count($JobIDArray) == $CheckCount ) break;
		sleep( 5 );
	}
}

////////////////////// Change Status /////////////////////////
$CheckCount = 0;
while ( $isOK == 1 ) {
	for($i = 0; $i < count($JobIDArray) && $isOK==1; $i++) {
		if ( $isOK == 1 ) { 
			$sql = "UPDATE MMS_Job SET status=".$FState; // status 50-작업대기중  or 100-완료
			$sql = $sql." where flag=0 and projectname = UNHEX('".$ProjectName."') and jobid='".$JobIDArray[$i]."'";
			$log->trace( $sql );
			if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
				$isOK = 0;
				$log->ERROR( $sql );
				$log->ERROR($ResText);
			}
			$CheckCount++;
		}
	}
	if ( $isOK==0 ) break;
	if ( count($JobIDArray) == $CheckCount ) break;
}

if ( $isOK == 1 )
	mysqli_commit($DBCon);
else 
	mysqli_rollback($DBCon);

mysqli_close($DBCon);

$log->trace("***********************************************");

?>
