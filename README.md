# kavo-cleaner

Windows 捷徑病毒（Shortcut Virus）清理工具，主要針對常見的「檔案／資料夾變成捷徑、原始資料被隱藏、`wscript.exe` 被拿來執行 `.vbs` 病毒」症狀。

## 使用方式

以系統管理員身分執行 `shortcut-virus-cleaner.bat`，輸入要修復的磁碟機或目錄，例如：

```text
F:\
Z:\Share
```

工具會：

1. 嘗試停止 `wscript.exe` / `cscript.exe`，但**不會刪除 Windows 內建的 `wscript.exe`**。
2. 將目標根目錄的 `.lnk`、`.vbs`，以及已知的 `loopqa`、`autorun.inf` 移到暫存隔離區，而不是直接永久刪除。
3. 還原目標路徑下檔案與資料夾的 Hidden / System / Read-only 屬性。
4. 將目前使用者 Startup 與 `%TEMP%` 中的 `.vbs` 移到同一類型的隔離區。
5. 不直接修改 Windows 啟動設定，讓使用者自行檢查可疑的 Windows Script Host 啟動項目。

完成後建議使用 Windows Security 執行完整掃描，並重新啟動電腦後再次確認磁碟內容。

## 為什麼不用原始 BAT 的無條件刪除方式？

原始草稿直接刪除所有 `.lnk`、`.vbs`，有誤刪正常檔案的風險。這個版本改成「先隔離、再確認」，並把清理範圍限制在使用者指定路徑的根目錄與感染流程中提到的典型位置。

此外，原方法提到的 `wscript.exe` 是 Windows 內建工具；感染只是借用它執行惡意腳本，因此工具只停止執行中的程序，不會刪除 `wscript.exe` 本身。

## 原始方法與貢獻來源

本專案的清理流程**源自 PTT NTUST_Talk 的歷史分享文章**：

- 原始貼文：<https://www.ptt.cc/bbs/NTUST_Talk/M.1370194255.A.FAE.html>
- 貼文中所描述的核心處理方式包含：停止 `wscript.exe`、移除 `loopqa` / `autorun.inf` / 可疑 `.vbs` / 捷徑檔、使用 `attrib` 還原隱藏與系統屬性，以及檢查 Startup / Temp 的殘留腳本。

本專案是在上述公開處理方法的基礎上進行腳本化與安全性改善，不主張原始貼文內容為本專案原創。

> 註：目前可查到的第三方整理頁也將該處理流程明確標註為「節錄自」上述 PTT 貼文；本專案以你指定的 PTT 原始連結作為主要來源，不把第三方整理頁當成原始來源。

## 重要限制

這不是完整的防毒軟體，也無法保證清除所有變種或持久化機制。若感染症狀持續，應使用正式防毒／EDR 工具進行完整掃描，並檢查排程工作、Startup、登錄機碼與其他持久化位置。

## License

尚未指定正式授權條款；使用前請自行評估風險。
