<?
require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('youtube_proc_bg_batch');

$BizType     = $argv[1];
$ProjectName = $argv[2];

$isOK = 1;
$status = 0;

$TableName = "YOUTUBE";

if ( $BizType < 0 || $BizType > 5 ) {
    $log->fatal("비정상 접속");
	exit;
}

if ( strlen($ProjectName) < 1 ) {
    $log->fatal("비정상 접속");
	exit;
}

$log->trace("*************** ".$TableName." Background **************");
$log->trace("*************** ProjectName=".$ProjectName."**************");

if ( !DB_Connect($DBCon, $ResText) ) {
	$log->ERROR("DB Connect FAIL");
	exit;
}

$sql = "SELECT down_URL, status";
$sql = $sql." FROM ".$TableName."_Job";
$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($sql);
	$log->ERROR($ResText);
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$down_URL = $row['down_URL'];
		$status   = (int)$row['status'];
		$log->trace( "Down URL : ".$down_URL);
	}
	else {
		$isOK = 0;
		$log->trace( "Not Found URL");
	}
}

///////////// Update State //////////////
if ( $isOK == 1 ) {
	if ( $status==3 ) { // 결제 완료 3 // <- 결제 직후 1회만 실행
		$sql = "UPDATE ".$TableName."_Job SET status=10";
		$sql = $sql." where flag=0 and projectname = UNHEX('".$ProjectName."')";
        $log->trace( $sql );
        if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
                $isOK = 0;
				$log->ERROR($sql);
                $log->ERROR($ResText);
        }
	}
}
////////////////////////////////////////////////
if ( $isOK == 1 ) mysqli_commit($DBCon);
else  mysqli_rollback($DBCon);
mysqli_close($DBCon);

//////////////////////////////////////////////// Download
if ( $isOK == 1 ) {
	$uploadfile = $UpFilePath.strtolower($ProjectName);
	$log->trace( "Video File=".$uploadfile);

	file_put_contents($uploadfile, fopen($down_URL, 'r'));
	$log->trace( "Download END : ".$ProjectName );
}

//////////////////////////////////////////////// analysis
$log->trace("CAll Begin speech_proc_bg_analysis");
shell_exec('php speech_proc_bg_analysis.do '.$BizType.' '.$ProjectName.' > /dev/null 2>/dev/null &'); 
$log->trace("CAll End speech_proc_bg_analysis");

$log->trace( "END >>>> PRJNAME : ".$ProjectName );
?>
