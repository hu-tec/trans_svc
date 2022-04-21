<?
require_once 'include.do';
require_once $include_db;
require_once $include_google_stt;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('speech_proc_bg_create_txt');

$BizType     = $argv[1];
$ProjectName = $argv[2];

$isOK = 1;
$job_name = "";
$Proc_FILE = "";
$srcLang = "";
$sample_rate = 0;
$channels = 0;
$trans_type = 0;
$status = 0;
$New_Status = 0;

$TableName = "";
if ( $BizType == 2 ) $TableName = "STT";
else if ( $BizType == 3 ) $TableName = "VIDEO";
else if ( $BizType == 4 ) $TableName = "S2S";
else if ( $BizType == 5 ) $TableName = "YOUTUBE";
else {
    $log->fatal("비정상 접속");
	exit;
}

if ( strlen($ProjectName) < 1 ) {
    $log->fatal("비정상 접속");
	exit;
}

$log->trace("*************** ".$TableName." Background Create Text Exec  **************");
$log->trace("*************** Create : BizType=".$BizType." ProjectName=".$ProjectName."**************");

if ( !DB_Connect($DBCon, $ResText) ) {
	$log->ERROR("DB Connect FAIL");
	exit;
}

$sql = "SELECT hex(job_name) as job_name, srcLang, sample_rate, channels, trans_type, status";
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
		$job_name    = strtolower($row['job_name']);
		$srcLang     = $row['srcLang'];
		$sample_rate = (int)$row['sample_rate'];
		$channels    = (int)$row['channels'];
		$trans_type  = (int)$row['trans_type'];
		$status      = (int)$row['status'];

		$Proc_FILE = $UpFilePath.$job_name.".mp3";

		$log->trace( "BEGIN >>>> PRJNAME : ".$ProjectName. " srcLang: ".$srcLang." status=".$status);
	}
	else {
		$isOK = 0;
		$log->trace( "Not Found Record - Project : ".$ProjectName);
	}
}

if ( $isOK == 1 ) {
	if( !file_exists($Proc_FILE) ) {
		$ResText = "처리할 파일을 찾을 수 없습니다.";
		$log->ERROR($ResText);
		$isOK = 0;
	}
}

///////////// Update State //////////////
if ( $isOK == 1 ) {
	if ( $status==3 || $status==10 ) { // 결제 완료 3 // <- 결제 직후 1회만 실행  < 10->YOUTUBE >
		$sql = "UPDATE ".$TableName."_Job SET status=11";
		$sql = $sql." where flag=0 and projectname = UNHEX('".$ProjectName."')";
        $log->trace( $sql );
        if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
                $isOK = 0;
				$log->ERROR($sql);
                $log->ERROR($ResText);
        }
        if ( $isOK == 1 ) mysqli_commit($DBCon);
        else  mysqli_rollback($DBCon);
	}
}

////////////////////////////////////////////////
if ( $isOK == 1 ) {
	if ( $status==3 || $status==10 ) { // 추출  < 10->YOUTUBE >
		//////////////// Make Text ///////////////////
		$Google_Response = GOOGLE_SpeechToText( $Proc_FILE, $job_name, $sample_rate, $srcLang, $channels );
		////////////////////////////////////////////////////////////
		
		if ( $Google_Response["isOK"] == 1 ) { 
			$Extract_Text = $Google_Response["TranScript"];

			$Extract_Text = preg_replace("/\'/","\\'", $Extract_Text);

			$log->trace("Extract_Text : ".$Extract_Text);
	
			// 텍스트 저장
			$sql = "UPDATE ".$TableName."_Job SET";
			$sql = $sql." src_text='".$Extract_Text."'";
			$sql = $sql." where flag=0 and projectname = UNHEX('".$ProjectName."')";
			$log->trace( $sql );
			if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
				$isOK = 0;
				$log->ERROR($sql);
				$log->ERROR($ResText);
			}
		}
		else {
			$isOK = 0;
			$log->ERROR("Google Trans : ErrorMsg = : ".$Google_Response["ErrorMsg"] );
		}
	}
}

////////////////////////////////////////////////
if ( $isOK == 1 ) {
	if ( $status==3 || $status==10 ) {  // < 10->YOUTUBE >
		if ( $trans_type == 1 ) $New_Status = 100;
		else $New_Status = 50;

		$sql = "UPDATE ".$TableName."_Job SET status=".$New_Status;
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

$log->trace( "END >>>> PRJNAME : ".$ProjectName. " srcLang: ".$srcLang );
?>
