<?
define("MMS_UID", "hutechc09");
define("MMS_PWD", "P@ssword884!!");
define("MMS_COD", "178793-WBezf-Jh51b");

/*********************** Who Am I *********************/
function MMSrc_WhoAmI() {
    $WhoAmI_log = Logger::getLogger('MMS_WhoAmI');

    $curl = curl_init();
    curl_setopt_array($curl, array(
        CURLOPT_URL => "https://cloud.memsource.com/web/api2/v1/auth/whoAmI?token=".$_SESSION['token'],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => "",
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 0,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST => "GET",
    ));
    $curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
    curl_close($curl);

    $WhoAmI_log->trace("--- Response ---\n".$curl_res);
	$WhoAmI_log->trace("--- ccode ---\n".$ccode);
	$WhoAmI_log->trace("--- cerror ---\n".$cerror);

	if ( $ccode == 0 ) { // Could not resolve host: cloud.memsource.com
		$WhoAmI_log->error("멤소스 연결 실패");
		return false;
	}

    $RetJson = json_decode($curl_res);

    // {"errorCode":"401","errorDescription":"auth: not logged"}
    if ( strlen($RetJson->errorCode) > 0 ) {
		$WhoAmI_log->trace("Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		return false;
	}
    return true;
}

/*********************** Login *********************/
function MMSrc_Login($isWeb) {
	global $Response;

    $Login_log = Logger::getLogger('MMS_Login');

    $curl = curl_init();
    curl_setopt_array($curl, array(
        CURLOPT_URL => 'https://cloud.memsource.com/web/api2/v1/auth/login',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => '',
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 0,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST => 'POST',
        CURLOPT_POSTFIELDS =>'{ "userName":"'.MMS_UID.'", "password":"'.MMS_PWD.'", "code":"'.MMS_COD.'"}',
        CURLOPT_HTTPHEADER => array('Content-Type: application/json'),
    ));
    $curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
    curl_close($curl);
    $Login_log->trace("--- Response ---\n".$curl_res);
	$Login_log->trace("--- ccode ---\n".$ccode);
	$Login_log->trace("--- cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$Response["RText"] = "문서처리 서버 연결 실패 - 관리자에게 문의 바랍니다.";
		$Login_log->error("멤소스 연결 실패");
		return false;
	}

    $RetJson = json_decode($curl_res);
    if ( strlen($RetJson->errorCode) > 0 ) {
		$Login_log->error("Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		$Response["RText"] = "번역 로그인 실패 - 관리자에게 문의 바랍니다.";
		return false;
	}

	if ( $isWeb == 1 )
	    $_SESSION['token'] = $RetJson->token;
	else 
		$Response['token'] = $RetJson->token;

	return true;
}

/*********************** Create Project *********************/
function MMSrc_Create_Project($name=null, $sLang=null, $tLang=null) {
	global $Response; 

    $PRJ_log = Logger::getLogger('MMS_ProjectCreate');
    
    $curl = curl_init();
    curl_setopt_array($curl, array(
        CURLOPT_URL => 'https://cloud.memsource.com/web/api2/v2/projects?token='.$_SESSION['token'],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => '',
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 0,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST => 'POST',
        CURLOPT_POSTFIELDS =>'{ "name": "'.$name.'", "sourceLang": "'.$sLang.'", "targetLangs": ["'.$tLang.'"]}',
        CURLOPT_HTTPHEADER => array( 'Content-Type: application/json' ),
    ));
    $curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
    curl_close($curl);

    $PRJ_log->trace("--- Response ---\n".$curl_res);
	$PRJ_log->trace("--- ccode ---\n".$ccode);
	$PRJ_log->trace("--- cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$Response["RText"] = "문서처리 서버 연결 실패 - 관리자에게 문의 바랍니다.";
		$PRJ_log->error("멤소스 연결 실패");
		return "";
	}

    $RetJson = json_decode($curl_res);
	if ( strlen($RetJson->errorCode) > 0 ) {
		$PRJ_log->error("Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		$Response["RText"] = "번역 프로젝트 생성 실패 - 관리자에게 문의 바랍니다.";
		return "";
	}
	
	return $RetJson->uid;
}

/*********************** Delete Project *********************/
function MMSrc_Delete_Project($ProjectID) {
	//global $Response; 

    $PRJ_log = Logger::getLogger('MMS_ProjectDelete');
    
    $curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => 'https://cloud.memsource.com/web/api2/v1/projects/'.$ProjectID.'?token='.$_SESSION['token'],
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => '',
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => 'DELETE',
		CURLOPT_HTTPHEADER => array('Content-Type: application/json'),
	));
	$curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
	curl_close($curl);

    $PRJ_log->trace("--- Response ---\n".$curl_res);
	$PRJ_log->trace("--- ccode ---\n".$ccode);
	$PRJ_log->trace("--- cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$PRJ_log->error("멤소스 연결 실패");
		return false;
	}

    $RetJson = json_decode($curl_res);
	if ( strlen($RetJson->errorCode) > 0 ) {
		$PRJ_log->error("Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		return false;
	}
	
	return true;
}

/*********************** Create Job *********************/
function MMSrc_Create_Job($ProjectID, $tLang, $savedFile, $FName, $Ext) {
	global $Response; 

    $Job_log = Logger::getLogger('MMS_JobCreate');

	$Job_log->trace("ProjecrtID=".$ProjectID." File=".$savedFile.", ".$FName);

	$handle = fopen($savedFile, "r");
	$data   = fread($handle, filesize($savedFile));

	$Job_log->trace("https://cloud.memsource.com/web/api2/v1/projects/".$ProjectID."/jobs?token=".$_SESSION['token']);

    $curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => "https://cloud.memsource.com/web/api2/v1/projects/".$ProjectID."/jobs?token=".$_SESSION['token'],
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => "",
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => "POST",
		CURLOPT_POSTFIELDS => $data,
		CURLOPT_HTTPHEADER => array(
			"content-disposition: filename*=UTF-8''".urlencode($FName.".".$Ext),
			"memsource: {\"targetLangs\":[\"".$tLang."\"]}",
			"Content-Type: application/octet-stream"
		),
	));
	$curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
	curl_close($curl);

    $Job_log->trace("--- Response ---\n".$curl_res);
	$Job_log->trace("--- ccode ---\n".$ccode);
	$Job_log->trace("--- cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$Response["RText"] = "문서처리 서버 연결 실패 - 관리자에게 문의 바랍니다.";
		$Job_log->error("멤소스 연결 실패");
		return "";
	}

    $RetJson = json_decode($curl_res);
	if ( strlen($RetJson->errorCode) > 0 ) {
		$Job_log->error("Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		$Response["RText"] = "번역 작업 생성 실패 - 관리자에게 문의 바랍니다.";
		return "";
	}

	$Job_log->trace("--- Return : ---".$RetJson->jobs[0]->uid);

	return $RetJson->jobs[0]->uid;
}
/*********************** Job status *********************/
function MMSrc_Job_Status($isWeb, $ProjectID, $jobUid) {
	global $Response; 

    $Job_log = Logger::getLogger('MMS_JobStatus');

	$Job_log->trace("ProjecrtID=".$ProjectID." jobUid=".$jobUid);

	$RURL = "https://cloud.memsource.com/web/api2/v1/projects/".$ProjectID."/jobs/".$jobUid."/statusChanges?token=";
	if ( $isWeb == 1 )
		$RURL = $RURL.$_SESSION['token'];
	else
		$RURL = $RURL.$Response['token'];

    $curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => $RURL,
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => "",
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => "GET",
	));
	$curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
	curl_close($curl);

    $Job_log->trace("--- Response ---\n".$curl_res);
	$Job_log->trace("--- ccode ---\n".$ccode);
	$Job_log->trace("--- cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$Response["RText"] = "문서처리 서버 연결 실패 - 관리자에게 문의 바랍니다.";
		$Job_log->error("멤소스 연결 실패");
		return "";
	}

    $RetJson = json_decode($curl_res);
	if ( strlen($RetJson->errorCode) > 0 ) {
		$Job_log->error("Create : Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		$Response["RText"] = "작업 상태 조회 실패 - 관리자에게 문의 바랍니다.";
		return "";
	}

	if ( $RetJson->statusChanges[0]->status ) $RetStr = $RetJson->statusChanges[0]->status;
	else $RetStr = "Continue";
	$Job_log->trace("--- Return : ---".$RetStr);

	return $RetStr;
}

/*********************** Get Segments *********************/
function MMSrc_Get_Segments($ProjectID, $jobUid, $segmentsCount) {
	global $Response; 
	$Trans_log = Logger::getLogger('MMS_GetSegments');

	///////////////////////////////  번역 결과 ///////////////////////////////////////////////
	$Trans_log->trace("--- Start ---\n");
	$curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => "https://cloud.memsource.com/web/api2/v1/projects/".$ProjectID."/jobs/".$jobUid."/segments?token=".$_SESSION['token']."&beginIndex=0&endIndex=".$segmentsCount,
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => "",
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => "GET",
	));
	$curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
	curl_close($curl);

	$Trans_log->trace("--- Result : Response ---\n".$curl_res);
	$Trans_log->trace("--- Result : ccode ---\n".$ccode);
	$Trans_log->trace("--- Result : cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$Response["RText"] = "문서처리 서버 연결 실패 - 관리자에게 문의 바랍니다.";
		$Trans_log->error("멤소스 연결 실패");
		return false;
	}

	$RetJson = json_decode($curl_res);
	if($RetJson->errorCode) {
		$Trans_log->error("Result : Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		$Response["RText"] = "번역 결과 조회 오류 발생 - 관리자에게 문의 바랍니다.";
		return false;
	}

	/*$ResText="";
	foreach ($RetJson->segments as $segment) {
		$Trans_log->trace("[".$segment->source."] [".$segment->translation."]");
		$ResText = $ResText."[".$segment->source."] [".$segment->translation."]\n";
	}
	$Trans_log->trace("--- segments Result ---\n".$ResText);
	$Response["TU"] = $ResText;*/

	return $RetJson->segments;
}

/*********************** Get Analysis Uid *********************/
function MMSrc_getAnalysisUid($jobUid) {
	global $Response; 
	$Analysis_log = Logger::getLogger('MMS_AnalysisUid');

	$curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => "https://cloud.memsource.com/web/api2/v1/analyses/byProviders?token=".$_SESSION['token'],
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => "",
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => "POST",
		CURLOPT_POSTFIELDS =>'{"jobs": [{"uid": "'.$jobUid.'"}], "type": "PreAnalyse"}',
		CURLOPT_HTTPHEADER => array("Content-Type: application/json"),
	));
	$curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
	curl_close($curl);

	$Analysis_log->trace("--- Response ---\n".$curl_res);
	$Analysis_log->trace("--- ccode ---\n".$ccode);
	$Analysis_log->trace("--- cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$Response["RText"] = "문서처리 서버 연결 실패 - 관리자에게 문의 바랍니다.";
		$Analysis_log->error("멤소스 연결 실패");
		return "";
	}

	$RetJson = json_decode($curl_res);
	if($RetJson->errorCode == "JOB_NOT_READY") {
		return $RetJson->errorCode;
	} 	
	else if( $RetJson->errorCode ) {
		$Response["RText"] = "문서번역 분석중 오류 발생 - 관리자에게 문의 바랍니다.";
		$Analysis_log->error("Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		return "";
	}
	
	return $RetJson->analyses[0]->analyse->id;
}

/*********************** result Analysis *********************/
function MMSrc_resultAnalysis($jobUid, $AnalysisUID) {
	global $Response; 
	$Analysis_log = Logger::getLogger('MMS_AnalysisResult');

	$curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => "https://cloud.memsource.com/web/api2/v1/analyses/".$AnalysisUID."/jobs/".$jobUid."?token=".$_SESSION['token'],
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => "",
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => "GET",
	));
	$curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
	curl_close($curl);

	$Analysis_log->trace("--- Response ---\n".$curl_res);
	$Analysis_log->trace("--- ccode ---\n".$ccode);
	$Analysis_log->trace("--- cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$Response["RText"] = "문서처리 서버 연결 실패 - 관리자에게 문의 바랍니다.";
		$Analysis_log->error("멤소스 연결 실패");
		return "";
	}

	$RetJson = json_decode($curl_res);

	if($RetJson->errorCode) {
		$Analysis_log->error("Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		$Response["RText"] = "문서번역 분석결과 조회중 오류 발생 - 관리자에게 문의 바랍니다.";
		return "";
	}

	return $RetJson->data->all;
}

/*********************** Translation *********************/
function MMSrc_Translation($isWeb, $ProjectID, $jobUid) {
	global $Response; 
	$Trans_log = Logger::getLogger('MMS_Translation');

	//////////////////////////////////////////////////////////////////////////////
	$Trans_log->trace("--- Start ---\n");

	$RURL = "https://cloud.memsource.com/web/api2/v1/projects/".$ProjectID."/jobs/preTranslate?token=";
	if ( $isWeb == 1 )
		$RURL = $RURL.$_SESSION['token'];
	else
		$RURL = $RURL.$Response['token'];

	$curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => $RURL,
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => "",
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => "POST",
		CURLOPT_POSTFIELDS =>"{jobs: [{uid: \"".$jobUid."\" }],'insertMachineTranslationIntoTarget': true, 'confirm100NonTranslatableMatches':true, 'setJobStatusCompleted':true}",
		CURLOPT_HTTPHEADER => array("Content-Type: application/json"),
	));
	$curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
	curl_close($curl);

	$Trans_log->trace("--- Result : Response ---\n".$curl_res);
	$Trans_log->trace("--- Result : ccode ---\n".$ccode);
	$Trans_log->trace("--- Result : cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$Response["RText"] = "문서처리 서버 연결 실패 - 관리자에게 문의 바랍니다.";
		$Trans_log->error("멤소스 연결 실패");
		return "";
	}

	$RetJson = json_decode($curl_res);
	if($RetJson->errorCode) {
		$Trans_log->error("Result : Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		$Response["RText"] = "번역중 오류 발생 - 관리자에게 문의 바랍니다.";
		return false;
	}
return true;
	/*//////////////////////////////////////////////////////////////////////////////
	$Trans_log->trace("--- segmentsCount : Start ---\n");
	$curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => "https://cloud.memsource.com/web/api2/v1/projects/".$ProjectID."/jobs/segmentsCount?token=".$_SESSION['token'],
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => "",
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => "POST",
		CURLOPT_POSTFIELDS =>"{'jobs': [{'uid': ".$jobUid."}]}",
		CURLOPT_HTTPHEADER => array("Content-Type: application/json"),
	));
	$curl_res = curl_exec($curl);
	curl_close($curl);

	$Trans_log->trace("--- segmentsCount Result : Response ---\n".$curl_res);
	$RetJson = json_decode($curl_res);
	//// ERROR 처리
	$segmentsCount = $RetJson->segmentsCountsResults[0]->counts->segmentsCount;
	$Trans_log->trace("--- segmentsCount Result : segmentsCount=".$segmentsCount);

	///////////////////////////////  번역 결과 ///////////////////////////////////////////////
	$Trans_log->trace("--- segments : Start ---\n");
	$curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => "https://cloud.memsource.com/web/api2/v1/projects/".$ProjectID."/jobs/".$jobUid."/segments?token=".$_SESSION['token']."&beginIndex=0&endIndex=".$segmentsCount,
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => "",
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => "GET",
	));
	$curl_res = curl_exec($curl);
	curl_close($curl);
	$Trans_log->trace("--- segments Result : Response ---\n".$curl_res);

	$RetJson = json_decode($curl_res);
	if($RetJson->errorCode) {
		$Trans_log->error("segments Result : Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		$Response["RText"] = "번역중 오류 발생 - 관리자에게 문의 바랍니다.";
		return false;
	}

	$ResText="";
	foreach ($RetJson->segments as $segment) {
		$Trans_log->trace("[".$segment->source."] [".$segment->translation."]");
		$ResText = $ResText."[".$segment->source."] [".$segment->translation."]\n";
	}
	$Trans_log->trace("--- segments Result ---\n".$ResText);
	$Response["TU"] = $ResText;

	return true;*/
}

/*********************** FileDownload *********************/
function MMSrc_FileDownload($isWeb, $ProjectID, $jobUid, $DownFile) {
	global $Response; 
	$Trans_log = Logger::getLogger('MMS_FileDownLoad');

	$Trans_log->trace("ProjecrtID=".$ProjectID." jobUid=".$jobUid." DownFILE=".$DownFile);

	$RURL = "https://cloud.memsource.com/web/api2/v1/projects/".$ProjectID."/jobs/".$jobUid."/targetFile?token=";
	if ( $isWeb == 1 )
		$RURL = $RURL.$_SESSION['token'];
	else
		$RURL = $RURL.$Response['token'];

	$curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => $RURL,
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => "",
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => "GET",
	));
	$curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
	curl_close($curl);

	$Trans_log->trace("--- Result : Response ---\n".$curl_res);
	$Trans_log->trace("--- Result : ccode ---\n".$ccode);
	$Trans_log->trace("--- Result : cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$Response["RText"] = "문서처리 서버 연결 실패 - 관리자에게 문의 바랍니다.";
		$Trans_log->error("멤소스 연결 실패");
		return "";
	}

	$RetJson = json_decode($curl_res);
	if($RetJson->errorCode) {
		$Trans_log->trace("--- ERROR Response ---\n".$curl_res);
		//if($RetJson->errorCode != "404") {
			$Trans_log->error("Result : Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
			$Response["RText"] = "파일 다운로드 중 오류 발생 - 관리자에게 문의 바랍니다.";
			return "";
		//}
	}

	//if($RetJson->errorCode == "404")
	//	$RetStr = "Continue";
	//else 
		$RetStr = "OK";
	$Trans_log->trace("--- Return : ---".$RetStr);
	
	if ( $RetStr == "OK" ) {
		$Trans_log->trace("--- FILE Save ---".$DownFile);
		$file = fopen($DownFile, "w+");
		fputs($file, $curl_res);
		fclose($file);
	}

	return $RetStr;
}

/*********************** Get supported languages *********************/
function MMSrc_SupportedLanguages() {
	global $Response; 
	$LPS_log = Logger::getLogger('MMS_SupportedLanguages');

	$LPS_log->trace("Get supported languages");

	$curl = curl_init();
	curl_setopt_array($curl, array(
		CURLOPT_URL => "https://cloud.memsource.com/web/api2/v1/languages?token=".$_SESSION['token'],
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => '',
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => 'GET'
	));

	$curl_res = curl_exec($curl);
	$ccode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$cerror = curl_error($curl);
	curl_close($curl);

	$LPS_log->trace("--- Result : Response ---\n".$curl_res);
	$LPS_log->trace("--- Result : ccode ---\n".$ccode);
	$LPS_log->trace("--- Result : cerror ---\n".$cerror);

	if ( $ccode == 0 ) {
		$Response["RText"] = "문서처리 서버 연결 실패 - 관리자에게 문의 바랍니다.";
		$LPS_log->error("멤소스 연결 실패");
		return "";
	}

	$RetJson = json_decode($curl_res);
	if($RetJson->errorCode) {
		$LPS_log->trace("--- ERROR Response ---\n".$curl_res);
		$LPS_log->error("Result : Error Code : ".$RetJson->errorCode." errorDescription :".$RetJson->errorDescription);
		$Response["RText"] = "지원 언어 조회 오류 발생 - 관리자에게 문의 바랍니다.";
		return "";
	}

	return $RetJson;
}
?>
