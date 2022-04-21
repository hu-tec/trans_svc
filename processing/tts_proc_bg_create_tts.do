<?
require_once 'include.do';
require_once $include_db;
require_once $include_google;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('tts_proc_bg_create_tts'); // call by expert_save_text.do

$ProjectName = $argv[2];

$isOK = 1;
$srcLang = "";
$tgtLang = "";
$src_text = "";
$tgt_text = "";
$trans_type = 0;
$status = 0;
$New_Status = 0;

if ( strlen($ProjectName) < 1 ) {
    $log->fatal("비정상 접속");
	exit;
}

if ( !DB_Connect($DBCon, $ResText) ) {
	$log->ERROR("DB Connect FAIL");
	exit;
}

$log->trace( "BEGIN >>>> PRJNAME : ".$ProjectName);

$sql = "SELECT srcLang, tgtLang, src_text, tgt_text, trans_type, status";
$sql = $sql." FROM MT_Job";
$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($sql);
	$log->ERROR($ResText);
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$srcLang = $row['srcLang'];
		$tgtLang = $row['tgtLang'];
		$src_text = $row['src_text'];
		$tgt_text = $row['tgt_text'];
		$trans_type = (int)$row['trans_type'];
		$status = (int)$row['status'];

		$log->trace("BEGIN >>>> PRJNAME : ".$ProjectName. " srcLang: ".$srcLang. " tgtLang: ".$tgtLang." trans_type=".$trans_type." status=".$status);
		$log->trace("src_text : ".$src_text);
		$log->trace("tgt_text : ".$tgt_text);
	}
	else {
		$isOK = 0;
		$log->trace( "Not Found Record - Project : ".$ProjectName);
	}
}

///////////////// Detect Source Language ///////////////////////////////
if ( $isOK == 1 ) {
	if ( $srcLang == 'at') {
		////////////////////////////////////////////////////////////
		$Google_Response = GOOGLE_Detect_Language( $src_text );
		////////////////////////////////////////////////////////////
		if ( $Google_Response["isOK"] == 1 ) {
			$srcLang = $Google_Response["Detect_Lang"];
			$log->trace( "Source Lang GET : ".$srcLang );
		}
		else {
			$isOK = 0;
			$Response["RText"] = "AI 자동 언어감지를 수행하지 못하였습니다. 관리자에게 연락 바랍니다.";
			$log->ERROR("Google Trans : ErrorMsg = : ".$Google_Response["ErrorMsg"] );
		}

		if ( $srcLang != 'at') { // Update DB Src_Lang
			$sql = "UPDATE MT_Job SET srcLang='".$srcLang."'";
			$sql = $sql." where flag=0 and projectname = UNHEX('".$ProjectName."')";
			$log->trace( $sql );
			if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
				$isOK = 0;
				$log->ERROR($sql);
				$log->ERROR($ResText);
			}
		}
	}
}

///////////////// Translation ///////////////////////////////
// MT만 선택한 경우 - 결제 후 1번만 실행...
if ( $isOK == 1 && $status==3 && $trans_type==2 ) { // Standard - Only MT + TTS
	$tgt_text = "";

	////////////////////////////////////////////////////////////
	$Google_Response = GOOGLE_Translate( [$src_text], $tgtLang );
	////////////////////////////////////////////////////////////
	if ( $Google_Response["isOK"] == 1 ) {
		$tgt_text = $Google_Response["Target_Text"];
		$log->trace("ALL Result Text : ".$tgt_text);
	}
	else {
		$isOK = 0;
		$Response["RText"] = "AI번역을 수행하지 못하였습니다. 관리자에게 연락 바랍니다.";
		$log->ERROR("Google Trans : ErrorMsg = : ".$Google_Response["ErrorMsg"] );
	}
}

///////////// Update State & Translation Result //////////////
if ( $isOK == 1 ) {
	if ( $status==3 ) { // <- 결제 직후 1회만 실행
		if ( $trans_type == 1 || $trans_type == 2 ) { // 결제 완료 3 > // Trans_Type:(Basic)1 - only TTS, 2(Standard) - MT + TTS
			$sql = "UPDATE MT_Job SET status=11, tgt_text='".$tgt_text."'";
		}
		else { // 나머지 Human 
			$sql = "UPDATE MT_Job SET status=50";
		}
		$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";
		
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

//////////////// Text To Speech ////////////////////////////////
if ( $isOK == 1 ) {
	// AI 이거나 Human 작업 완료 > 파일 생성
	if ( ($status==3 && ($trans_type == 1 || $trans_type == 2)) || $status==52 ) { // 결제완료(Only AI) or PE 완료
		for ($i=0; $i<2 && $isOK==1; $i++) {
			if ($i == 0 ) {
				$Lang = $srcLang;
				$Text = $src_text;
			}
			else {
				$Lang = $tgtLang;
				$Text = $tgt_text;
			}

			$log->trace(" Lang: ".$Lang." :: Text : ".$Text);

			$UUID = exec('uuidgen');
			$UUID = strtolower(str_replace('-', '', $UUID));
			$RLink = $DownFilePath.$UUID.".mp3";

			//////////////// Make TTS ///////////////////
			GOOGLE_TextToSpeech( $Lang, $Text, $RLink );
			////////////////////////////////////////////////////////////
			$log->trace(" Lang: ".$Lang." :: Create Audio File : ".$RLink);

			$sql = "UPDATE MT_Job SET";
			if ($i == 0 )  $sql = $sql." src_audio";
			else $sql = $sql." tgt_audio";
			$sql = $sql."=UNHEX('".$UUID."')";
			$sql = $sql." where flag=0 and projectname = UNHEX('".$ProjectName."')";
			$log->trace( $sql );
			if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
				$isOK = 0;
				$log->ERROR($sql);
				$log->ERROR($ResText);
			}

			if ( $trans_type == 1 ) break; // TTS만
		}
	}
}

////////////////////////////////////////////////
if ( $isOK == 1 ) {
	if ( $status==3 && ( $trans_type == 1 || $trans_type == 2) ) {  // AI인 경우만 최초 1회 실행
		$sql = "UPDATE MT_Job SET status=100";
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

$log->trace( "END >>>> PRJNAME : ".$ProjectName. " srcLang: ".$srcLang. " tgtLang: ".$tgtLang );

?>
