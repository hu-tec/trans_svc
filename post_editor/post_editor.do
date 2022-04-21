<div class="bg-gray">
    <div class="wrap">
        <div class="guide-box">
            <div class="popupInfoTransBox">
                <h6>작업 순서</h6>
                <p>1. 원문의 문장을 문장 단위로 분리하고, 음성을 들으면서 원문을 교정하시기 바랍니다.<br>
                    2. [①줄 단위 정리] 버튼을 클릭하여 문장 분리와 음성의 내용이 정확한지 확인하여 주십시오.<br>
                    3. [②AI번역] 버튼을 클릭하여 AI의 번역문이 올 때까지 잠깐 대기해 주십시오.<br>
                    &nbsp;&nbsp;&nbsp;&nbsp;Google 또는 Naver 중 1번만 선택할 수 있으며, 다시 선택할 수 없으니 주의 바랍니다.<br>
                    4. 하단에 문장 단위로 편집할 수 있도록 창이 나타납니다. 번역문을 편집하시면 됩니다.<br>
                    5. 작업중 [③임시 저장]해 주시고, [④작업 완료]를 선택하면 화면 종료 됩니다.
                </p>
            </div>
            <button type="button" class="btn-s btn-white stepWork">작업순서</button>
            <div style="color:#6C3483;height:31px;margin-top:10px;" id="MessageDiv"></div>
            <button type="button" id="BTN_TArea_Toggle" class="btn-m btn-gray">텍스트 창 숨기기</button>
            <button type="button" id="BTN_Auto_Split" class="btn-m btn-blue" disabled>①줄 단위 정리</button>
            <select id="AI_Trans_Select" disabled>
                <option value="-" selected>②AI번역선택</option>
            </select>
            <!-- <button type="button" id="BTN_AI_Trans_Google" class="btn-m btn-white" disabled>②Google AI 번역</button>
            <button type="button" id="BTN_AI_Trans_Naver" class="btn-m btn-white" disabled>②Naver AI 번역</button> -->
            <button type="button" id="BTN_Temp_Save" class="btn-m btn-white" disabled>③임시 저장</button>
            <button type="button" id="BTN_Save_End" class="btn-m btn-white" disabled>④작업 완료</button>
        </div>
        
        <div id="DIV_TextArea" class="row">
            <div class="box div-box mr-5">
                <div class="row">
                    <div class="text-guide"><b>원문</b></div>
                    <div class="text-guide" id="SrcLang"></div>
                    <audio id='STTAudio' controls src='' hidden></audio>
                </div>
                <div class="text-box">
                    <textarea id="SrcTextArea" onkeydown="resize(this)" onkeyup="resize(this)"></textarea>
                </div>
            </div>
            <div class="box div-box ml-5">
                <div class="row">
                    <div class="text-guide"><b>번역문</b></div>
                    <div class="text-guide" id="TgtLang"></div>
                </div>
                <div class="text-box">
                    <textarea id="TgtTextArea" onkeydown="resize(this)" onkeyup="resize(this)" disabled></textarea>
                </div>
            </div>
        </div>

        <div id="DIV_ED" style="display:none;">
            <table id="ED_TABLE" width="100%">
                <thead>
                    <tr class="tableHead row">
                        <th><div style="text-align:center !important">기계번역 or 이전편집</div></th>
                        <th><div style="text-align:center !important">원문 : <font color="blue">편집</font></div></th>
                        <th><div style="text-align:center !important;color:blue">번역문 : 편집</div></th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>
