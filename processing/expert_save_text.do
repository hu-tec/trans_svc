<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('expert_save_text');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$isTMP = (int)$_POST["isTMP"];
	$BizType = (int)$_POST["svc_type"];
	$ProjectName = $_POST["Project"];
	$trans_type  = (int)$_POST["trans_type"];

	$srcLang = $_POST["srcLang"];
	$SrcArray = $_POST["SrcArray"];

	if ( isset( $_POST['TgtArray'] ) ) {
		$tgtLang = $_POST["tgtLang"];
    	$TgtArray = $_POST["TgtArray"];
	}

	$expertid = $_SESSION['useridkey'];
	$svccode  = $_SESSION['svccode'];
	$utype    = (int)$_SESSION['utype'];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("********** expert = ".$expertid." **********");
$log->trace("isTMP : ".$isTMP." Project: ".$ProjectName);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $BizType == 1 ) $DB_Table_Name = "MT";
else if ( $BizType == 2 ) $DB_Table_Name = "STT";
else if ( $BizType == 3 ) $DB_Table_Name = "VIDEO";
else if ( $BizType == 4 ) $DB_Table_Name = "S2S";
else if ( $BizType == 5 ) $DB_Table_Name = "YOUTUBE";

$isUpdate=0;
$isOK = 1;
$Response = array();
$ResText = "";

for($i=0; $i<count($SrcArray); $i++) {
    $log->trace("One Source Text : [".$SrcArray[$i]."]");
	if ( $BizType == 1 || $trans_type > 2 ) // TTS or MT (STT, Video, STS)
		$log->trace("One Target Text : [".$TgtArray[$i]."]");
}

if ( $BizType == 1 || $trans_type > 2 ) { // TTS or MT (STT, Video, STS)
	if ( count($SrcArray) != count($TgtArray) ) {
		$isOK = 0;
		$ResText = "원문과 번역문의 개수가 다릅니다.";
	}
}

if ( $isOK == 1 && ( $BizType == 1 || $trans_type > 2 ) ) { // TTS or MT (STT, Video, STS)
	$sql = "SELECT count(*) as cnt FROM ".$DB_Table_Name."_PostEdit";
	$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";
	//$sql = $sql." && expert_id=".$expertid." && svccode=".$_SESSION['svccode'];
	$sql = $sql." && svccode=".$_SESSION['svccode'];
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($sql);
		$log->ERROR($ResText);
	}
	else {
		if ( $row = mysqli_fetch_array($DBQRet) ) {
			if ( (int)$row['cnt'] != 0 ) $isUpdate = 1;
		}
	}
}

if ( $isOK == 1 && ( $BizType == 1 || $trans_type > 2 ) ) { // TTS or MT (STT, Video, STS)
	if ( $isUpdate == 1 ) {
		$sql = "UPDATE ".$DB_Table_Name."_PostEdit SET flag=1";
		$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";
		//$sql = $sql." && expert_id=".$expertid." && svccode=".$_SESSION['svccode'];
		$sql = $sql." && svccode=".$_SESSION['svccode'];
	}
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($sql);
		$log->ERROR($ResText);
	}
}
/////////////////////////////////////////
$All_Src_Text = "";
$All_Tgt_Text = "";
if ( $isOK == 1 ) {
	$Cnt = 0;
	for($i=0; $i<count($SrcArray) && $isOK==1; $i++) {
		$Src_Text = preg_replace("/\'/","\\'", $SrcArray[$i]);
		if ( $BizType == 1 || $trans_type > 2 ) // TTS or MT (STT, Video, STS)
			$Tgt_Text = preg_replace("/\'/","\\'", $TgtArray[$i]);

		if ( $Cnt > 0 ) {
			$All_Src_Text = $All_Src_Text."\r\n";
			if ( $BizType == 1 || $trans_type > 2 ) // TTS or MT (STT, Video, STS)
				$All_Tgt_Text = $All_Tgt_Text."\r\n";
		}
		$All_Src_Text = $All_Src_Text.$Src_Text;
		if ( $BizType == 1 || $trans_type > 2 ) // TTS or MT (STT, Video, STS)
			$All_Tgt_Text = $All_Tgt_Text.$Tgt_Text;
		
		if ( $BizType == 1 || $trans_type > 2 ) { // TTS or MT (STT, Video, STS)
			if ( $isUpdate == 0 ) {
				if ( $BizType == 1 ) { // TTS
					$sql = "INSERT INTO ".$DB_Table_Name."_PostEdit (projectname, expert_id, svccode, sdate, seq, src_text_one, tgt_text_one) VALUES (";
					$sql = $sql."UNHEX('$ProjectName'), $expertid, $svccode, now(), $i, '$Src_Text', '$Tgt_Text')";
				}
				else {
					$sql = "INSERT INTO ".$DB_Table_Name."_PostEdit (projectname, expert_id, svccode, sdate, lang, seq, text_one) VALUES (";
					$sql = $sql."UNHEX('$ProjectName'), $expertid, $svccode, now(), '$srcLang', $i, '$Src_Text')";
					$log->trace( $sql );
					if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) $isOK = 0;

					$sql = "INSERT INTO ".$DB_Table_Name."_PostEdit (projectname, expert_id, svccode, sdate, lang, seq, text_one) VALUES (";
					$sql = $sql."UNHEX('$ProjectName'), $expertid, $svccode, now(), '$tgtLang', $i, '$Tgt_Text')";
				}
			}
			else {
				if ( $BizType == 1 ) { // TTS
					$sql = "UPDATE ".$DB_Table_Name."_PostEdit SET flag=0, sdate=now()";
					$sql = $sql." , src_text_one='".$Src_Text."', tgt_text_one='".$Tgt_Text."'";
					$sql = $sql." where projectname = UNHEX('".$ProjectName."')";
					//$sql = $sql." && expert_id=".$expertid." && svccode=".$_SESSION['svccode']." && seq=".$i;
					$sql = $sql." && svccode=".$_SESSION['svccode']." && seq=".$i;
				}
				else {
					$sql = "UPDATE ".$DB_Table_Name."_PostEdit SET flag=0, sdate=now(), text_one='".$Src_Text."'";
					$sql = $sql." where projectname = UNHEX('".$ProjectName."')";
					//$sql = $sql." && expert_id=".$expertid." && svccode=".$_SESSION['svccode']." && lang='".$srcLang."' && seq=".$i;
					$sql = $sql." && svccode=".$_SESSION['svccode']." && lang='".$srcLang."' && seq=".$i;
					$log->trace( $sql );
					if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) $isOK = 0;

					$sql = "UPDATE ".$DB_Table_Name."_PostEdit SET flag=0, sdate=now(), text_one='".$Tgt_Text."'";
					$sql = $sql." where projectname = UNHEX('".$ProjectName."')";
					//$sql = $sql." && expert_id=".$expertid." && svccode=".$_SESSION['svccode']." && lang='".$tgtLang."' && seq=".$i;
					$sql = $sql." && svccode=".$_SESSION['svccode']." && lang='".$tgtLang."' && seq=".$i;
				}
			}
			$log->trace( $sql );
			if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) $isOK = 0;
		}
		$Cnt++;
	}
}

if ( $isOK == 1 ) { // Complete PE, Text Update State 52 : 휴먼 완료
	$log->trace("ALL Source Text : [".$All_Src_Text."]");
	if ( $BizType == 1 || $trans_type > 2 ) // TTS or MT (STT, Video, S2S, YOUTUBE)
		$log->trace("ALL Target Text : [".$All_Tgt_Text."]");

	$status = 51;
	if ( $isTMP == 0 ) $status = 52;

	if ( $BizType == 1 || $trans_type > 2 ) { // TTS+MT or (STT, Video, S2S, YOUTUBE) >> MT 
		$sql = "UPDATE ".$DB_Table_Name."_Job SET status=".$status.", src_text='".$All_Src_Text."', tgt_text='".$All_Tgt_Text."'";
	}
	else { // Only STT
		$sql = "UPDATE ".$DB_Table_Name."_Job SET status=".$status.", src_text='".$All_Src_Text."'";
	}
	//$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."') && expert_id=".$expertid;
	$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($sql);
		$log->ERROR($ResText);
	}	
}

if ( $isOK == 1 ) mysqli_commit($DBCon);
else  mysqli_rollback($DBCon);

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( $isOK == 1 ) {
	if ( $isTMP == 1 )
		$ResText = "임시 저장되었습니다.";
	else
		$ResText = "최종 저장 완료 하였습니다.";
}
if ( strlen($ResText) > 0 )
	$Response["RText"] = $ResText;

$log->trace("SEND Result : ".json_encode($Response));
print json_encode($Response);

if ( $isTMP == 0 ) { // 작업 완료
	$BG_PROC_Name = "";
	/* $BizType : 0 : DOC - 결제 후 AI > Human 마무리 */
	if ( $BizType == 1 ) $BG_PROC_Name = "tts_proc_bg_create_tts";
	/* $BizType : 2 : STT - 결제 후 AI Text 추출 > Human Text 처리 */
	/* $BizType : 3 : Video - 결제 후 AI Text 추출 > Human Text 처리 */

	else if ( $BizType == 4 ) $BG_PROC_Name = "speech_proc_bg_create_tts";
	// else if ( $BizType == 5 ) $BG_PROC_Name = "youtube_proc_bg_create";

	if ( $BizType == 1 || $BizType == 4 ) { // TTS , S2S
		$log->trace("CAll Begin ".$BG_PROC_Name." BizType=".$BizType." ProjectName=".$ProjectName);
		shell_exec("php ".$BG_PROC_Name.".do ".$BizType." ".$ProjectName." > /dev/null 2>/dev/null &"); 
		$log->trace("CAll End ".$BG_PROC_Name." BizType=".$BizType." ProjectName=".$ProjectName);
	}
}
?>
