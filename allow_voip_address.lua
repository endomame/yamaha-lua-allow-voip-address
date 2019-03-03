-- netvolanteDNSに登録されたIPのみを許可するスクリプト
-- 前提条件
-- 文字コードはascii
-- LuaのバージョンはLua 5.1.4以降
-- フィルター設定は以下を前提とする
-- 5060ポートに対するtcp,udp両方をブロックしなければならないため
-- ip filter 200081 pass * * tcp,udp * 5060
--
-- 変数設定 -----------------------------
-- nslookup対象のIPアドレスを設定
command_hostname = {
 "<<hostname1>>",
 "<<hostname2>>",
 "<<hostname3>>",
 "<<hostname4>>"
}

-- フィルタナンバーを設定
filter_number = "200081"

-- メインの処理 -------------------------
-- 120秒に1回ループするためwhile true do にて実行
while true do
  -- nslookupを実行しフィルタ用のIPアドレスを取得
  command_hostname_result = nil

  for i, cmd_hostname in ipairs(command_hostname) do
      rtn, str = rt.command("nslookup " .. cmd_hostname)
      if (not rtn) or (not str) then
          -- コマンド実行失敗の場合処理を中止	
          break
      end

      if ( command_hostname_result == nil ) then
        command_hostname_result = str
        else
        command_hostname_result = command_hostname_result .. "," .. str
      end
  end

  -- nslookupの実行がすべて成功した場合にフィルタを再設定
  if rtn then
    -- 組み立てたIPアドレスの改行を削除
    command_hostname_result = string.gsub(command_hostname_result, "\r\n", "" )
    -- フィルタ設定コマンド作成
    filter_command = "ip filter ".. filter_number .. " pass " .. command_hostname_result .. " * tcp,upd * 5060"
    -- 設定されている内容と同一の場合は設定を中止するための比較用フィルタ設定を取得
    search_filter_command= "ip filter ".. filter_number .. " pass " .. command_hostname_result .. " %* tcp,udp %* 5060"

    -- 設定されているフィルタ内容との比較
    match_setting_filter = nil
    rtn, str = rt.command("show config")
    if rtn then
      match_setting_filter = string.match(str , search_filter_command)
      -- IPアドレスが更新されている場合は設定を実施
      if ( match_setting_filter == nil )then 
      -- アナログポートが利用されていない場合のみフィルタ設定を実施
      status_analog = nil
      rtn, str = rt.command("show status analog")
      status_analog = string.match(str , "(TEL1: Not Connected.).*(TEL2: Not Connected.)")
        if ( status_analog ) then
          -- フィルタを設定
          rtn, str = rt.command(filter_command)
            -- コマンドが正常終了すればsavaを実施
            if rtn then
              rtn, str = rt.command("save")
            end
        end
      end
    end
  end
-- 120秒スリープ
 rt.sleep(120)
end

