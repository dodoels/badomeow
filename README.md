# ForFeralSake (至暗.八方.豹读诗书.哈基米要你命三千八)

<div align="center">

**WoW 12.0 Midnight 德鲁伊战斗监控插件**

*基于暴雪官方 CooldownViewer 系统，自动同步所有技能数据*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/dodoels/badomeow)

[功能特性](#功能特性) • [安装](#安装) • [使用](#使用) • [自定义](#自定义) • [致谢](#致谢)

</div>

---

## 简介

ForFeralSake 是一个专为 WoW 12.0 Midnight 德鲁伊设计的战斗监控插件。在 WeakAuras 因 API 限制无法使用的情况下，本插件通过 hook 暴雪官方的 CooldownViewer 系统，实现了自动化、零配置的技能监控。

**核心理念：**
- ✅ **零配置** — 自动同步暴雪 CooldownViewer，无需手动添加技能 ID
- ✅ **12.0 兼容** — 完全遵守 WoW 12.0 API 限制，无 taint，无 secret value 错误
- ✅ **高度自定义** — 支持 Masque 皮肤、自定义贴图背景、独立拖动每个组件
- ✅ **全专精支持** — 平衡、野性、守护、恢复四大专精自动切换监控内容
- ✅ **变身适配** — 人形态/猫形态/熊形态自动切换对应资源条（能量/怒气/星涌/法力）

---

## 功能特性

### 🎯 核心监控
- **增益/触发 (Buff/Proc)** — 高亮显示重要 buff 和 proc 触发
- **核心技能 (Essential)** — 主要输出/防御技能冷却监控
- **工具技能 (Utility)** — 辅助技能冷却监控
- **资源条** — 能量/怒气/星涌/法力值动态显示
- **连击点 (Combo Points)** — 猫德专属，彩虹渐变显示
- **蓝条 (Mana)** — 变身时显示法力值

### 🎨 外观自定义
- **Masque 皮肤支持** — 兼容 Masque:Cirque 等皮肤包，图标可变圆形/方形/各种造型
- **贴图系统** — 最多 10 个独立贴图面板，可作为背景或装饰
  - 支持 `.tga` / `.blp` 格式
  - 自动扫描 `Textures/` 文件夹，下拉菜单选择
  - 可调宽高、透明度、颜色、翻转
- **资源条材质** — 资源条和蓝条的填充/背景纹理可分别自定义
- **独立拖动** — 每个组件（技能监控、资源条、贴图面板）都可独立拖动定位
- **整体缩放** — 0.5x ~ 2.0x 全局缩放
- **全局偏移** — X/Y 偏移滑块精确移动所有组件

### ⚙️ 便捷操作
- **右键快速锁定/解锁** — 右键点击任意组件快速切换锁定状态
- **Shift+拖动整体移动** — 按住 Shift 拖动任意组件，所有组件一起移动
- **设置预览模式** — 打开设置时自动显示所有已启用组件，方便调整布局
- **独立开关** — 每个组件可单独开关，不需要的监控直接关掉

---

## 安装

### 方法 1：手动安装
1. 下载最新版本：[Releases](https://github.com/dodoels/badomeow/releases)
2. 解压到 `World of Warcraft\_retail_\Interface\AddOns\`
3. 确保文件夹名为 `ForFeralSake`
4. 重启游戏

### 方法 2：Git Clone
```bash
cd "World of Warcraft\_retail_\Interface\AddOns"
git clone https://github.com/dodoels/badomeow.git ForFeralSake
```

### 可选：Masque 皮肤支持
如果想使用圆形图标等自定义皮肤：
1. 安装 [Masque](https://www.curseforge.com/wow/addons/masque)
2. 安装皮肤包（如 [Masque: Cirque](https://www.curseforge.com/wow/addons/masque-cirque)）
3. 在 ForFeralSake 设置中启用"启用 Masque 皮肤"
4. 使用 `/msq` 打开 Masque 设置选择皮肤

---

## 使用

### 基础命令
```
/ffs              打开设置面板
/ffs lock         锁定所有组件
/ffs unlock       解锁所有组件（可拖动）
/ffs reset        重置所有位置到默认
/ffs debug        打印调试信息
```

别名：`/forferalsake`

### 快捷操作
| 操作 | 效果 |
|------|------|
| **左键拖动** | 移动单个组件 |
| **Shift + 左键拖动** | 整体移动所有组件 |
| **右键点击任意组件** | 快速锁定/解锁 |
| **全局 X/Y 偏移滑块** | 精确移动所有组件（包括贴图） |

### 首次设置建议
1. 输入 `/ffs unlock` 解锁组件
2. 拖动每个组件到想要的位置
3. 在设置中调整图标大小、间距、资源条宽高
4. 锁定后正常使用

---

## 自定义

### 添加自定义贴图背景

**步骤：**
1. 准备你的图片（`.png` / `.jpg` / `.tga` / `.blp`）
2. 放入 `Interface\AddOns\ForFeralSake\Textures\` 文件夹（可创建子文件夹如 `Backgrounds/`）
3. 如果是 PNG/JPG，运行转换脚本：
   ```bash
   cd Interface\AddOns\ForFeralSake
   python generate_manifest.py --convert
   ```
4. 重载游戏（`/reload`）
5. 在设置 → 贴图面板 → 点"选择素材"按钮，你的贴图会出现在下拉菜单

**提示：**
- WoW 只支持 `.tga` 和 `.blp` 格式
- 推荐尺寸为 2 的幂次方（256, 512, 1024 等）以获得最佳性能
- 透明通道（Alpha）完全支持

### 自定义资源条材质

在设置 → 资源条样式 → 资源条材质区域：
- **资源条填充** — 能量/怒气条的填充纹理
- **资源条背景** — 能量/怒气条的背景纹理
- **蓝条填充** — 法力条的填充纹理
- **蓝条背景** — 法力条的背景纹理

内置多种暴雪原生材质，也可选择你添加到 `Textures/` 的自定义材质。

---

## 技术架构

### 核心设计
本插件采用 **Ayije_CDM 的 reparenting 策略**：
- Hook 暴雪 `CooldownViewer*` 系统的 `itemFramePool`
- 将暴雪的 item frame **重定向父级到 UIParent**，然后相对定位到我们的容器
- 完全避免接触 secret values（冷却时间、buff 数据等）
- 暴雪负责数据更新，我们只负责布局和样式

### Secret Value 处理
- **资源条**：`UnitPower` / `UnitPowerMax` 直接传给 `SetValue` / `SetMinMaxValues`（原生支持 secret values）
- **文本显示**：使用 `issecretvalue` 检查，只在安全时格式化文本
- **冷却监控**：完全不读取冷却数据，让暴雪的 frame 自己更新

### 模块化架构
- **Constants.lua** — 常量、默认配置、专精定义
- **Core.lua** — 事件处理、专精/变身检测、主逻辑
- **ViewerHook.lua** — CooldownViewer hook、section frame 管理、Masque 集成
- **ResourceBar.lua** — 资源条、连击点、蓝条的创建和更新
- **TextureRegistry.lua** — 贴图注册表、材质管理
- **TextureOverlay.lua** — 贴图面板组件系统
- **Settings.lua** — 游戏内设置面板 UI

---

## 致谢

本插件由 **BILIBILI@SOSO财高八抖** 四处搜刮纯AI沥尽心血毫无原创打造而成。

### 开源项目致谢

本项目参考、借鉴了以下开源项目：

| 项目 | 作者 | 协议 | 贡献 |
|------|------|------|------|
| [Ayije_CDM](https://addons.wago.io/addons/ayijecdm) | Ayije | — | CooldownViewer hook 核心参考、secret value 处理模式 |
| [WeakAuras2](https://github.com/WeakAuras/WeakAuras2) | Buds, Infus, Rivers, Stanzilla 及社区 | GPL v2 | 战斗显示设计哲学、贴图系统灵感 |
| [SenseiClassResourceBar](https://github.com/Snsei987/SenseiClassResourceBar) | Snsei987 | MIT | 资源条架构、Settings API 参考 |
| [Arc UI](https://github.com/devdeadviz/arc-ui) | devdeadviz | — | 模块化 UI 设计思路 |
| [Masque](https://github.com/SFX-WoW/Masque) | StormFX (JJ Sheets) | — | 图标皮肤引擎 API |

---

## 开发

### 环境要求
- Python 3.7+ （用于贴图转换和 manifest 生成）
- Pillow （图片处理）：`pip install Pillow`

### 添加新贴图素材
```bash
# 1. 把图片放到 Textures/ 文件夹
cp your_image.png Textures/Backgrounds/

# 2. 运行生成脚本（自动转换 + 生成 manifest + 部署）
python generate_manifest.py --convert

# 3. 提交
git add Textures/ TextureManifest.lua
git commit -m "asset: add new texture"
```

### 本地开发
```bash
# Clone 仓库
git clone https://github.com/dodoels/badomeow.git
cd badomeow

# 创建符号链接到游戏目录（或直接在游戏目录开发）
# Windows (管理员权限):
mklink /D "D:\WOW\China\_retail_\Interface\AddOns\ForFeralSake" "E:\path\to\badomeow-repo"

# 每次修改后游戏内 /reload 即可测试
```

---

## 路线图

### v1.x 当前功能
- [x] 自动 CooldownViewer hook
- [x] 四大专精支持
- [x] 变身形态自动切换资源条
- [x] Masque 皮肤集成
- [x] 贴图面板系统
- [x] 自定义资源条材质
- [x] 独立拖动每个组件

### v2.x 计划功能
- [ ] 法术 on cast / on proc 贴图触发动画
- [ ] 更多内置贴图素材
- [ ] 音效系统（如果 12.0 允许）
- [ ] 多套预设布局快速切换
- [ ] 导入/导出配置字符串
- [ ] LibSharedMedia 集成（更多字体和材质选择）

---

## 常见问题

### Q: 为什么不像 WeakAuras 那样手动配置技能？
**A:** WoW 12.0 移除了大量 API，手动配置技能需要读取冷却时间等数据，这些都是 secret values。我们的方案是直接用暴雪官方的 CooldownViewer，它已经帮你配置好了所有技能，我们只是把它重新布局和美化。

### Q: 进入战斗后组件消失？
**A:** 检查是否锁定了组件。战斗中无法解锁，需要脱战后 `/ffs unlock`。

### Q: Masque 皮肤没有生效？
**A:** 确保：
1. 已安装 Masque 和皮肤包
2. 在 ForFeralSake 设置中勾选"启用 Masque 皮肤"
3. 使用 `/msq` 打开 Masque 设置，找到 ForFeralSake 分组，选择皮肤

### Q: 贴图不显示？
**A:** 检查：
1. 文件格式是否为 `.tga` 或 `.blp`（PNG/JPG 需要转换）
2. 路径是否正确：`Interface\AddOns\ForFeralSake\Textures\your_file.tga`
3. 是否勾选了"贴图 #X"启用开关
4. 宽高是否设置合理（不要设置为 0）

### Q: 如何恢复默认布局？
**A:** `/ffs reset` 或在设置中点击"重置所有位置"按钮。

---

## 许可证

MIT License

Copyright (c) 2026 ForFeralSake contributors

本插件由 **BILIBILI@SOSO财高八抖** 四处搜刮纯AI沥尽心血毫无原创打造而成。

详见 [LICENSE](LICENSE) 文件。

---

## 反馈与支持

- **Bug 报告**：[GitHub Issues](https://github.com/dodoels/badomeow/issues)
- **功能建议**：[GitHub Discussions](https://github.com/dodoels/badomeow/discussions)
- **联系作者**：BILIBILI@SOSO财高八抖

---

<div align="center">

**如果这个插件帮到了你，请给个 ⭐ Star！**

Made with 🐆 for Feral Druids

</div>
