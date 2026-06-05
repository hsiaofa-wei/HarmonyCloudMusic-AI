## 部分截图展示 
<img width="400"  alt="屏幕截图 2026-06-05 105632" src="https://github.com/user-attachments/assets/953d094d-c7bb-413e-b935-52250752d21b" />
<img width="400"  alt="屏幕截图 2026-06-05 105715" src="https://github.com/user-attachments/assets/c7ca85a9-aa71-44ba-af79-709eed4a8196" />
<img width="400"  alt="屏幕截图 2026-06-05 105653" src="https://github.com/user-attachments/assets/631c0407-9b60-47d1-bb73-12d8f0799592" />
<img width="400"  alt="屏幕截图 2026-06-05 105638" src="https://github.com/user-attachments/assets/587e22ff-6319-4338-bfcd-b0e319eb6999" />

>更多内容请您下载观看

## HarmonyCloudMusic-AI

是一款运行在 HarmonyOS 上的音乐 App 练手项目，在经典「云音乐」界面基础上，内置 **云音乐 AI** 助手，让听歌、搜歌、聊音乐更自然。

主要能力：

- **多 Tab 音乐首页**：推荐 / 发现 / 动态 / 我的，深色主题 UI
- **AI 音乐助手**：悬浮球唤起，支持多轮对话、上下文记忆、DeepSeek 思考模式
- **语音交互**：推荐页语音搜索（ASR）+ AI 回复 TTS 朗读
- **在线播放**：AVPlayer 播放、播放列表、进度与封面展示
- **启动页**：Banner 闪屏 + 倒计时跳过

技术栈：**HarmonyOS NEXT · ArkTS · ArkUI · AVPlayer · HTTP · 语音识别 / TTS**

---

## 核心功能亮点

| 模块 | 说明 |
|------|------|
| 多模态交互 | 文本对话 + 语音输入 + TTS 语音播报 |
| AI 人设 | 「云音乐 AI」专属 System Prompt，专注歌曲/歌手/歌单/场景推荐 |
| 思考模式 | 可选 DeepSeek `reasoning_content` 流式展示与折叠 |
| 全局悬浮球 | 可拖拽、贴边吸附，任意页面唤起 AI |
| 音乐播放 | 全局 `AppStorage` 状态，列表与播放页联动 |
| 深色 UI | 统一主题色 `#E85A88`，沉浸式安全区适配 |

---

## 项目结构

```
three_group/
├── entry/src/main/ets/
│   ├── pages/          # Start / Layout / Recommend / Find / Play / Mine …
│   ├── chat/           # AI 聊天（DeepSeek API、Panel、Float）
│   └── utils/          # AVPlayer、Ability 上下文
├── AppScope/           # 应用级资源
└── docs/screenshots/   # README 展示用截图
```

---

## 快速启动

### 环境要求

- [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)（建议 5.0+）
- HarmonyOS SDK API 12+
- 真机或模拟器（语音能力建议真机调试）

### 1. 克隆项目

```bash
git clone https://github.com/<your-username>/HarmonyCloudMusic-AI.git
cd HarmonyCloudMusic-AI
```

### 2. 配置 DeepSeek API Key

编辑 `entry/src/main/ets/chat/service/DeepSeekApi.ets`：

```typescript
export class ApiConfig {
  static API_KEY: string = 'sk-你的DeepSeek密钥';  // 替换为你的 key
  static BASE_URL: string = 'https://api.deepseek.com/chat/completions';
  static MODEL: string = 'deepseek-v4-flash';
  static ENABLE_THINKING: boolean = false;  // 可选：开启思考模式
}
```

> 请勿将真实密钥提交到公开仓库，可使用本地环境变量或 `.gitignore` 忽略的配置文件。

### 3. 运行

1. 用 DevEco Studio 打开项目根目录  
2. 连接 HarmonyOS 设备或启动模拟器  
3. 点击 **Run** 构建并安装 `entry` 模块  

---

## 权限说明

应用已声明网络、麦克风等权限（见 `entry/src/main/module.json5`），用于：

- 在线歌曲与封面加载  
- DeepSeek API 调用  
- 语音识别与 TTS  

---

## 项目亮点 & 个人收获

- HarmonyOS 原生 ArkTS 全栈 UI 开发实践  
- DeepSeek API 流式对话 + 思考链展示  
- 语音识别 / TTS 与音乐场景结合  
- 悬浮窗交互、全局播放状态管理  
- 模块化 `chat` 包，便于复用到其他 App  

---


欢迎 Star & Fork！如果对 Spring AI、多模态应用或 Vue 3 全栈开发感兴趣，欢迎 Issues 交流～

