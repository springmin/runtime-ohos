# PIN-BUMP：三 workflow `MAUI_OHOS_REF` → `44dcef8d15`（pin 漂移转绿）（2026-10-12）

> 触发：interaction CI 红两轮同签名（`38204552669` @`34bcaa4` / `38215361043` @`34f87cb`）——三 workflow `MAUI_OHOS_REF` 仍 `36da77cba4`，ow 套件（MEDIA-RESIDUALS +2 / SUBWIN-COMPLETED +3，total 804 floor 784）的 `mediaresiduals coldstart` 源 pin 要求的 maui `44dcef8d15` 未在 pin 内。纪律：只动 pin/注释、无构建、maui 与 #49–#54 资产零改动。

## 1) 变更 / 提交

- interaction/pixel/host-export：`default:` + `env.MAUI_OHOS_REF` `36da77cba4` → `44dcef8d15eb8af568197cca6bb00a0bcca15725`；pin 历史注释补齐 fbd91e17bc / 54631780a3 / 36da77cba4 / 44dcef8d15 四代，计数按实况（套件 801/804 floor 784、导出 164/164、abc 623,784/`58c5829b…`）。
- ow `master` 提交 **`cbbc340`**（`34f87cb..cbbc340`，HTTP/1.1 直连推送、非强推）；maui tip 未动。
- `44dcef8d15` = 切片单文件 `OpenHarmonyMediaElement.PlayAsync` 冷启有界（50 ms 轮询/1.5 s 上限）等页，首 ack 即页面的答案；managed-only、无新 DllImport、光栅输出不动（hlsrange 同源切片在壳页侧，已随 MEDIA-RESIDUALS 发货）。

## 2) CI 6/6 @ `cbbc340`

- push 自动 5：interaction `38217123278`（`[suite] checks=801 total=804 floor=784 assert=True`、`coldstart wait=True`、0 Unhandled）· pixel `38217123272` · host-export `38217123113` · ridgraph `38217123248` · markdownlint `38217123232`。
- harmony：路径过滤不含本 diff → **手动 dispatch** `38217183783` 绿；旧红签名（`coldstart wait=False`）@`34bcaa4`/`34f87cb` 消除。

## 3) 不确定项

- harmony 对不含其路径的推送需手动 dispatch（既有约定）；kit #55 状态未动（rc.2 WAIT、不切包）。
