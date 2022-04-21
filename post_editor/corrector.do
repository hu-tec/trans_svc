<div class="bg-gray">
    <div class="wrap">
        <div class="guide-box">
            <div class="popupInfoTransBox">
                <h6>작업 순서</h6>
                <p>
                    1. 편집을 위해 문장 단위로 분리해 주십시오.<br>
                    2. [①줄 단위 정리] 버튼을 클릭하여 문장 분리된 내용을 확인하여 주십시오.<br>
                    3. 음성을 들으면서 문장을 교정하여 주십시오.<br>
                    4. 작업중 [②임시 저장]해 주시고, [③작업 완료]를 선택하면 화면 종료 됩니다.
                </p>
            </div>
            <button type="button" class="btn-s btn-white stepWork">작업순서</button>
            <div style="color:#6C3483;height:31px;margin-top:10px;" id="MessageDiv"></div>
            <button type="button" id="BTN_Auto_Split" class="btn-m btn-blue">①줄 단위 정리</button>
            <button type="button" id="BTN_Temp_Save" class="btn-m btn-green">②임시 저장</button>
            <button type="button" id="BTN_Save_End" class="btn-m btn-red">③작업 완료</button>
        </div>
        <div id="DIV_TextArea">
            <div class="box div-box">
                <div class="row">
                    <div class="text-guide"><b>문장 교정 및 편집</b></div>
                    <div class="text-guide" id="SrcLang"></div>
                    <audio id='STTAudio' controls src=''></audio>
                </div>
                <div class="text-box">
                    <textarea id="SrcTextArea" onkeydown="resize(this)" onkeyup="resize(this)"></textarea>
                </div>
            </div>
        </div>
    </div>
</div>
