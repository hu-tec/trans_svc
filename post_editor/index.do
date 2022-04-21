<?
require_once $_SERVER['DOCUMENT_ROOT'].'/inc/inc_common.do';

if ( !isset( $_SESSION['useridkey'] ) ) {
	exit;
}
if ( !isset($_GET['b']) || !isset($_GET['t']) || !isset($_GET['p']) ) {
	exit;
}

$BizType = -1;
$isCorrectTrans = "";
$ProjectName = "";
if ( $_SERVER["REQUEST_METHOD"] == "GET" ) {
    if ( isset($_GET['b']) ) $BizType = (int)$_GET["b"];
    if ( isset($_GET['t']) ) $isCorrectTrans = $_GET["t"];
    if ( isset($_GET['p']) ) $ProjectName = $_GET["p"];
}
?>

<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta HTTP-EQUIV='Expires' CONTENT='-1'>
    <meta http-equiv=pragma content=no-cache>

    <title>
<?
$Title_H = "";
if ( $BizType == 1 ) $Title_H = "TTS";
if ( $BizType == 2 ) $Title_H = "STT";
if ( $BizType == 3 ) $Title_H = "Video";
if ( $BizType == 4 ) $Title_H = "S2S";
if ( $BizType == 5 ) $Title_H = "Youtube";
if ( $isCorrectTrans == 'c') $Title_H = $Title_H." 교정 편집";
else if ( $isCorrectTrans == "t") $Title_H = $Title_H." 번역 편집";
echo $Title_H;
?>
    </title>
    
    <!-- <link rel="stylesheet" href="/common/css/bootstrap.min.css">
    <link rel="stylesheet" href="/common/css/jquery.dataTables.min.css"> -->
    <link rel="stylesheet" href="/css/editer.css?v=<?echo time()?>">

    <script type="text/javascript" src="/common/js/bootstrap.bundle.min.js"></script>  
    <script type="text/javascript" src="/common/js/jquery-3.5.1.js"></script>
    <script type="text/javascript" src="/common/js/jquery.dataTables.min.js"></script>
    <script type="text/javascript" src="/inc/inc_js.js?v=<?echo time()?>"></script>
    <style>
        select {
            text-align: center;
            border-color: #f0f0f0;
            word-wrap: normal;
            text-transform: none;
            border-radius: 4px;
            margin: 4px 0 4px 15px;
            font-size: 14px;
            font-weight: 600;
            background: white;
            color : black;
            /* background: #982dbc;
            color : white; */
        }
</style>

</head>
<body>
<div class="loading">
    <div class="d-flex justify-content-center">
        <div class="spinner-border" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
    </div>
</div>

<?
if ( $isCorrectTrans == "c") include "corrector.do";
else if ( $isCorrectTrans == "t") include "post_editor.do";
?>

</body>
<script type="text/javascript">
<?echo "var PJT='".$ProjectName."';".PHP_EOL;?>
<?echo "var BIZ=".$BizType.";".PHP_EOL;?>

function LockScreen() {
    document.querySelector(".d-flex").classList.add("active");
    document.querySelector(".loading").classList.add("active");
}
function UnLockScreen() {
    document.querySelector(".d-flex").classList.remove("active");
    document.querySelector(".loading").classList.remove("active");
}

<?
if ( $isCorrectTrans == "c") include "corrector.js";
else if ( $isCorrectTrans == "t") include "post_editor.js";
?>
</script>
</html>