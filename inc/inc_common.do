<?
session_start();
date_default_timezone_set("Asia/Seoul");
ini_set('display_errors', '1');
ini_set('display_startup_errors', '1');

$UpFilePath   = "/hutechc/file_upload/";
$DownFilePath = "/hutechc/file_download/";

$Root       = "/home/htc_service";
$DocRoot    = $Root."/trans_svc";
$Google_SDK = $Root;

// Include
$include_db    = $DocRoot.'/inc/inc_db.do';
$include_mmsrc = $DocRoot.'/inc/inc_mmsrc.do';

$include_google = $DocRoot.'/inc/inc_google.do';
$include_google_stt = $DocRoot.'/inc/inc_google_stt.do';

$include_naver = $DocRoot.'/inc/inc_naver.do';
$include_systran = $DocRoot.'/inc/inc_systran.do';

// Logger
$MMS_Logger_Config    = $Root.'/log4php/config_mms.xml';
$Google_Logger_Config = $Root.'/log4php/config_google.xml';
require_once $Root.'/log4php/src/main/php/Logger.php';

/***  Session Check ***
if( isset($_SESSION['LAST_ACT']) && time() - $_SESSION['LAST_ACT'] > 60*60*2 ){
	header('Location: logout.php');
}
$_SESSION['LAST_ACT'] = time();
*/

?>
