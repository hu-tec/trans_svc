<?
/*
    SESSION
        useridkey, svccode, utype, grade
        point
*/
require_once $_SERVER['DOCUMENT_ROOT'].'/inc/inc_common.do';

if ( isset( $_SESSION['ProjectName'] ) ) unset($_SESSION['ProjectName']);

$host=$_SERVER["HTTP_HOST"];
$ReqBiz=0;
$ReqPage = "trans_doc";
if ( $_SERVER["REQUEST_METHOD"] == "GET" ) {
    if ( isset($_GET['svc']) ) $ReqPage = $_GET["svc"];
    if ( isset($_GET['cty']) ) $ReqBiz  = $_GET["cty"];
}

$FullPath = "sub_".$ReqPage."/".$ReqPage.".";
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta HTTP-EQUIV='Expires' CONTENT='-1'>
    <meta http-equiv=pragma content=no-cache>

    <title>MetaTrans::AI번역 서비스</title>

    <script type="text/javascript" src="/common/js/jquery-3.5.1.js"></script>
    <script src="https://code.jquery.com/ui/1.13.0/jquery-ui.js"></script>
    <script type="text/javascript" src="/inc/inc_js.js?v=<?echo time()?>"></script>
    <script type="text/javascript" src="/common/js/script.js"></script>

    <style type="text/css">
        html, body{
            /*font-family: "Nanum Gothic" !important;*/
            font-size: 0.9rem !important;
        }
        body {
            margin: 0 auto;
            padding: 0;
        }
    </style>

<?
if ( file_exists($FullPath."head") )
    include $FullPath."head";
?>
    <script src="https://kit.fontawesome.com/49e4bc6b3c.js" crossorigin="anonymous"></script>
    <link rel="stylesheet" href="/intro_css/style.css?v=<?echo time()?>">
    <link rel="stylesheet" href="/intro_css/custom.css?v=<?echo time()?>">
    <link rel="stylesheet" href="/css/xeicon.css?v=<?echo time()?>">
    <link rel="stylesheet" href="/css/layout.css?v=<?echo time()?>">
    <link rel="stylesheet" href="/css/style.css?v=<?echo time()?>">

</head>
<body>
<?
if($host!="service.metatrans.ai")
	include "header.page";

if ( file_exists($FullPath."page") ) include $FullPath."page";

if($host!="service.metatrans.ai")
	include "footer.page";
?>
</body>
<script type="text/javascript">
<?
if ( isset( $_SESSION['useridkey'] ) ) echo 'var UserCheck="isOn";'.PHP_EOL;
else echo 'var UserCheck="";'.PHP_EOL;
if ( isset( $_SESSION['point'] ) ) echo "var UserPoint=".$_SESSION['point'].";".PHP_EOL;
else echo "var UserPoint=0;".PHP_EOL;
if ( isset( $_SESSION['utype'] ) ) echo "var UserType=".$_SESSION['utype'].";".PHP_EOL;
else echo "var UserType=0;".PHP_EOL;
?>

function MainBTNSet(CurrID) {
    $("#MainBtn").children().removeClass('btn-primary');
    $("#MainBtn").children().removeClass('btn-outline-secondary');
    nodes = $("#MainBtn").children();
    nodes.each(function(){
        if ( CurrID == $(this).attr("id") ) $(this).addClass('btn-primary');
        else $(this).addClass('btn-outline-secondary');
    });
}
function PageLoad(Name, isSet) {
    Page = Name;
    Cty = isSet;

    JLink = self.location.pathname + "?svc=" + Page;
    JLink += "&cty=" + Cty;
    self.location.href = JLink;
}
/*******************************************/
$(document).ready(function() {
<?
$CurrPage = $ReqPage;
if ( (int)$ReqBiz == 1 ) {
    $CurrPage = $ReqPage;
}
echo "    MainBTNSet('".$CurrPage."');".PHP_EOL;
?>

    if ( UserCheck == "isOn" ) {
        if ( UserType == 21 ) $("#my_expert").css('display', '');
        if ( UserType == 99 ) $("#my_manage").css('display', '');
        $("#LILogout").css('display', '');
        $("#LILogin").css('display', 'none');
        $("#LIJoin").css('display', 'none');
        $("#LIPoint").html('<span></span>');
        $("#LIPoint span").append("Point "+AddComma(UserPoint));
        //$("#LIPoint").text("Point "+AddComma(UserPoint));
    }
    else {
        $("#LILogout").css('display', 'none');
        $("#LILogin").css('display', '');
        $("#LIJoin").css('display', '');
        $("#my_expert").css('display', 'none');
        $("#my_manage").css('display', 'none');
    }
    /* Header Click */
    $("#MainBtn button").on('click',function (e) {
        PageLoad(this.id, 1);
    });
    $("#NavBtn button").on('click',function (e) {
        PageLoad(this.id, 0);
    });
    $("#user_mypage_point, #my_expert, #my_manage, #user_mypage_document, #user_mypage_info").on('click',function (e) {
        if ( UserCheck == "isOn" )
            PageLoad(this.id, 0);
    });
    /* Footer Click */
    $("#CPYLink a").on('click',function (e) {
        PageLoad(this.id, 0);
    });
    /* Service Click */
    $("#ServiceLink a").on('click',function (e) {
        if ( this.id.substr(0, 6) == "trans_") PageLoad(this.id, 1);
        else PageLoad(this.id, 0);
    });
    /* UserLink Click */
    $("#UserLink a").on('click',function (e) {
        if ( UserCheck == "isOn" && (this.id == "login" || this.id == "join") ) return;
        PageLoad(this.id, 0);
    });

<?if ( file_exists($FullPath."js") ) include $FullPath."js"; ?>
});

    /******************** Description ***************************************/
    $(".hoverPopup").on('mouseover',function (e) {
        pidx = $(".hoverPopup").index(this);
        $(".showPopup").eq(pidx).addClass("active");
    });
    $(".hoverPopup").on('mouseout',function (e) {
        pidx = $(".hoverPopup").index(this);
        $(".showPopup").eq(pidx).removeClass('active');
    });
</script>
</html>
