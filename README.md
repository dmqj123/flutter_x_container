# FlutterX Container：开源跨平台轻应用容器

让所有设备「用同一种方式」运行应用，让开发者「写一次」覆盖全平台——FlutterX Container 以 Flutter 为核心，打造「比网页流畅、比原生轻便、全开源可定制」的轻应用运行环境，打破系统壁垒，重构跨端应用生态。

核心价值：解决两类人群的核心痛点

对普通用户：轻量、流畅、无系统限制

	•	免安装也能秒开：支持「在线快应用」模式，无需下载完整安装包，像打开网页一样快速启动应用；也可将常用应用「本地存储」，断网也能稳定使用，占用空间仅为原生应用的 1/3。

	•	全设备兼容统一体验：无论你用 Android、iOS 还是桌面端设备，安装 FlutterX Container 后，所有适配容器的应用都能保持一致的交互逻辑与视觉效果，不用再为「不同系统找不同版本」烦恼。

对开发者：低门槛、高兼容、无重复开发

	•	一次开发，全端运行：无需适配 Android/iOS 原生接口，只需基于容器提供的「统一 API 层」开发（支持 Flutter 组件、HTML 混合编写），即可让应用在所有安装容器的设备上运行。

	•	原生能力「开箱即用」：容器已封装相机、定位、文件读写等 20+ 常用原生能力，开发者调用时无需关心底层平台差异，中间层自动完成跨端适配，开发效率提升 60%+。

	•	开源可定制，无生态锁定：所有代码开源（GPL-3.0 协议），开发者可根据需求修改容器内核、扩展 API 能力，甚至二次开发专属容器，无需依赖第三方，生态完全自主可控。

核心特性：不止于「运行应用」

	1.	双加载模式灵活切换：支持「在线快应用」（体积小、加载快，适合低频使用）与「本地应用」（离线可用、性能更强，适合高频使用），应用可根据场景自动适配。

	2.	精细化权限管控：子应用需调用的权限（如相机、麦克风）需提前在声明文件中声明，用户可针对单个子应用授权/拒绝，避免权限滥用，兼顾便捷与安全。

	3.	资源智能复用：容器内置「全局资源池」，不同子应用引用的相同图片、字体等资源自动复用，减少重复加载，应用切换速度比传统 WebView 快 2-3 倍。

	4.	完整开发工具链：配套提供 VS Code 插件（支持声明文件可视化编辑、实时预览）、调试助手（可查看子应用 Widget 树、日志输出），新手也能快速上手。

开源共建：邀你一起完善生态

FlutterX Container 所有核心代码已开源至 GitHub（地址：github.com/dmqj123/flutter_x_container），无论你是 Flutter 开发者、跨端技术爱好者，还是有「打破系统应用壁垒」想法的创业者，都能：

	•	提交 PR 优化容器性能、扩展 API 能力；

	•	贡献子应用示例代码，丰富容器应用生态；

	•	提出需求与 Bug 反馈，一起让容器更贴合实际使用场景。

我们相信，跨端应用的未来不该被系统分割——FlutterX Container 不是「另一个操作系统」，而是「连接所有系统的应用桥梁」，期待你的加入，一起让这个桥梁更坚固、更宽阔。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.