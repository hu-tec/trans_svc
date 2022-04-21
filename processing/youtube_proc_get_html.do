<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('youtube_proc_get_html');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$SrcLang = $_POST["SrcLang"];
	$TgtLang = $_POST["TgtLang"];
    $YouTubeURL = $_POST["YouTubeURL"];

	$useridkey   = $_SESSION['useridkey'];
	$svccode     = $_SESSION['svccode'];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

// $header = apache_request_headers(); 
// if( isset($header["X-Forwarded-For"]) ){ 
//   $UserIP = $header["X-Forwarded-For"]; 
// }
// else { 
// 	$UserIP = $_SERVER['REMOTE_ADDR']; 
// }

$isOK = 1;
$Response = array();
$ResText = "";

$log->trace("********** useridkey=".$useridkey." **********");
$log->trace(" SrcLang:".$SrcLang.", TgtLang:".$TgtLang.", URL:".$YouTubeURL);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$sql = "SELECT count(*) as cnt FROM YOUTUBE_Job";
$sql = $sql." where flag=0 && useridkey=".$useridkey." && svccode=".$svccode." && status<3";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		if ( (int)$row['cnt'] > 0 ) {
			$ResText = "진행 중인 건이 있습니다.\r\n결제하시거나 삭제 후 진행 바랍니다.";
			$isOK = -1;
		}
	}
	else {
		$log->ERROR( $sql );
		$ResText = "정보를 조회할 수 없습니다.";
		$isOK = 0;
	}
}

///////////////////////////////////////////////////////
if ( $isOK == 1 ) {
	$GetJSon = "";
	$HTML = file_get_contents($YouTubeURL); // GET Web Contents

	if ( $HTML !== false ) {
		$ST_POS = strpos($HTML, '{"responseContext":');
		if ($ST_POS === false) $isOK = 0;
		else {
			$ED_POS = strpos($HTML, "};</script>")+1;
			if ($ED_POS === false) $isOK = 0;
			else {
				if ( $ED_POS <= $ST_POS ) $isOK = 0;
			}
		}
	}
	else $isOK = 0;

	if ( $isOK == 0 ) $ResText = "요청한 URL에서 정보를 찾을 수 없습니다.";
}

// Find Video of Minimum Size 
if ( $isOK == 1 ) {
	$F_URL = "";
	$C_Len=0;
	$log->trace("Start Pos:".$ST_POS." End Pos:".$ED_POS);
    $GetJSon = substr($HTML, $ST_POS, $ED_POS-$ST_POS);
	//$log->trace($GetJSon);

	$JSON = json_decode($GetJSon);
	// $log->trace("itag : ".$JSON->streamingData->formats[0]->itag);
	// $log->trace("mimeType : ".$JSON->streamingData->formats[0]->mimeType);
	// $log->trace("contentLength : ".$JSON->streamingData->formats[0]->contentLength);
	//$log->trace("url : ".$JSON->streamingData->formats[0]->url);

	$log->trace("** formats ** ");
	for($i = 0 ; $i < count($JSON->streamingData->formats) ; $i++){
		//if ( substr($JSON->streamingData->formats[$i]->mimeType, 0, 9) == "video/mp4" ) {
			$CL = 0;
			$AC = 0;
			if ( isset($JSON->streamingData->formats[$i]->contentLength) ) {
				$CL = (int)$JSON->streamingData->formats[$i]->contentLength;
				if ( $CL>0 ) {
					if ( $C_Len == 0 ) $C_Len = $CL;
				}
			}
			if ( isset($JSON->streamingData->formats[$i]->audioChannels) ) {
				$AC = (int)$JSON->streamingData->formats[$i]->audioChannels;
				if ( $CL>0 && $AC>0 ) {
					$log->trace("itag[".$i."] : ".$JSON->streamingData->formats[$i]->itag);
					$log->trace("mimeType[".$i."] : ".$JSON->streamingData->formats[$i]->mimeType);
					$log->trace("contentLength[".$i."] : ".$JSON->streamingData->formats[$i]->contentLength);
					$log->trace("url[".$i."] : ".$JSON->streamingData->formats[$i]->url);
					$log->trace(" ");
				}
			}

			if ( $CL>0 && $CL<$C_Len && $AC>0  ) {
				$C_Len = $CL;
				$F_URL = $JSON->streamingData->formats[$i]->url;
			}
		//}
	}

	$log->trace("** adaptiveFormats ** ");
	for($i = 0 ; $i < count($JSON->streamingData->adaptiveFormats) ; $i++){
		//if ( substr($JSON->streamingData->adaptiveFormats[$i]->mimeType, 0, 9) == "video/mp4" ) {
			$CL = 0;
			$AC = 0;
			if ( isset($JSON->streamingData->adaptiveFormats[$i]->contentLength) ) {
				$CL = (int)$JSON->streamingData->adaptiveFormats[$i]->contentLength;
				if ( $CL>0 ) {
					if ( $C_Len == 0 ) $C_Len = $CL;
				}
			}
			if ( isset($JSON->streamingData->adaptiveFormats[$i]->audioChannels) ) {
				$AC = (int)$JSON->streamingData->adaptiveFormats[$i]->audioChannels;
				if ( $CL>0 && $AC>0 ) {
					$log->trace("itag[".$i."] : ".$JSON->streamingData->adaptiveFormats[$i]->itag);
					$log->trace("mimeType[".$i."] : ".$JSON->streamingData->adaptiveFormats[$i]->mimeType);
					$log->trace("contentLength[".$i."] : ".$JSON->streamingData->adaptiveFormats[$i]->contentLength);
					$log->trace("url[".$i."] : ".$JSON->streamingData->adaptiveFormats[$i]->url);
					$log->trace(" ");
				}
			}
			
			if ( $CL>0 && $CL<$C_Len && $AC>0  ) {
				$C_Len = $CL;
				$F_URL = $JSON->streamingData->adaptiveFormats[$i]->url;
			}
		//}
	}

	$log->trace("title : ".$JSON->videoDetails->title);
	$log->trace("lengthSeconds : ".$JSON->videoDetails->lengthSeconds);

	if ( $C_Len>0 && strlen($F_URL) ) {
		$log->trace("FIND - C_Len : ".$C_Len);
		$log->trace("FIND - F_URL : ".$F_URL);

		$Response["Video_Title"] = $JSON->videoDetails->title; // ori_fname
		$Response["Video_Time"]  = $JSON->videoDetails->lengthSeconds; // duration
		$Response["Video_URL"]   = $F_URL;
		$Response["Video_Size"]  = $C_Len;
	}
	else {
		$isOK = 0;
		$ResText = "다운로드할 Video를 찾을 수 없습니다.";
	}
}
///////////////////////////////////////////////////////
// $log->trace("UserIP : ".$UserIP);

// if ( $isOK == 1 ) mysqli_commit($DBCon);
// else  mysqli_rollback($DBCon);
mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( strlen($ResText) > 0 )
	$Response["RText"] = $ResText;

// if ( $isOK == 1 ) {
//     $_SESSION['ProjectName'] = $ProjectName;
// }
$log->trace("SEND Result : ".json_encode($Response));
print json_encode($Response);

//file_put_contents("Test_Youtube_Stream_webC", fopen($F_URL, 'r'));

?>