<?
//ffmpeg -i bc70379eb1cd45698ffb5f6b5702e459 -f flac -vn bc70379eb1cd45698ffb5f6b5702e460
//ffprobe bc70379eb1cd45698ffb5f6b5702e460 -show_streams -print_format json

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('speech_proc_bg_analysis');

$BizType     = (int)$argv[1];
$ProjectName = $argv[2];

$isOK = 1;
$ResText="";

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

$log->trace("*************** ".$TableName." Background Analysis Exec  **************");

if ( !DB_Connect($DBCon, $ResText) ) {
	$log->ERROR("DB Connect FAIL");
	exit;
}

$log->trace("*************** ffmpeg & ffprobe : BizType=".$BizType." ProjectName=".$ProjectName."**************");

$job_name = exec('uuidgen');
$job_name = strtolower(str_replace('-', '', $job_name));

// State 1
$sql = "UPDATE ".$TableName."_Job SET";
if ( $BizType != 5 ) $sql = $sql." status=1,"; // YOUTUBE아닌 경우
$sql = $sql." job_name=UNHEX('".$job_name."')";
$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
        $isOK = 0;
        $log->ERROR($sql);
        $log->ERROR($ResText);
}
if ( $isOK == 1 ) mysqli_commit($DBCon);
else  mysqli_rollback($DBCon);

// ffmpeg & ffprobe
$Info = "";
if ( $isOK == 1 ) {
    $EXEC_STR = 'ffmpeg -i '.$UpFilePath.$ProjectName.' -f flac -vn '.$UpFilePath.$job_name.'.mp3';
    $log->trace( $EXEC_STR );
    shell_exec($EXEC_STR);

    $EXEC_STR = 'ffprobe '.$UpFilePath.$job_name.'.mp3 -show_streams -print_format json';
    $log->trace( $EXEC_STR );
    $Info = shell_exec($EXEC_STR);
    $log->trace("Audio Info : ".$Info );
}
if ( $isOK == 1 ) {
    if ( strlen($Info) < 1 ) {
        $isOK = 0;
        $ResText = "오디오 정보를 확인할 수 없습니다.";
    }
}

$sample_rate = 0;
$channels = 0;
$duration = 0;

if ( $isOK == 1 ) {
    $Audio_Info = json_decode($Info, true);
    $AInfo = $Audio_Info["streams"][0];
    $log->trace("sample_rate : ".$AInfo["sample_rate"] );
    $log->trace("channels : ".$AInfo["channels"] );
    $log->trace("duration : ".$AInfo["duration"] );

    $sample_rate = $AInfo["sample_rate"];
    $channels = $AInfo["channels"];
    $duration = (int)ceil($AInfo["duration"]);
    $log->trace("sample_rate : ".$sample_rate );
    $log->trace("channels : ".$channels );
    $log->trace("duration : ".$duration );
}

if ( $isOK == 1 ) {
    // state 2
    $sql = "UPDATE ".$TableName."_Job SET";
    if ( $BizType != 5 ) $sql = $sql." status=2,"; // YOUTUBE아닌 경우
    $sql = $sql." sample_rate=".$sample_rate.", channels=".$channels.", duration=".$duration;
    $sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";
    $log->trace( $sql );
    if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
        $isOK = 0;
        $log->ERROR($sql);
        $log->ERROR($ResText);
    }
}

////////////////////////////////////////////////
if ( $isOK == 1 ) mysqli_commit($DBCon);
else  mysqli_rollback($DBCon);
mysqli_close($DBCon);

if ( strlen($ResText)>0 )
	$log->trace( $ResText );

//////////////////////////////////////////////// Background for YOUTUBE
if ( $isOK == 1 && $BizType == 5) { // Only YOUTUBE
    $log->trace("CAll Begin speech_proc_bg_create_txt BizType=".$BizType." ProjectName=".$ProjectName);
    shell_exec("php speech_proc_bg_create_txt.do ".$BizType." ".$ProjectName." > /dev/null 2>/dev/null &"); 
    $log->trace("CAll End speech_proc_bg_create_txt BizType=".$BizType." ProjectName=".$ProjectName);
}

$log->trace( "END >>>> PRJNAME : ".$ProjectName );

?>