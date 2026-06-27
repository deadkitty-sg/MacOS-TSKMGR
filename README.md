### 任务管理器，但是macOS ###

### Taskmanager, but on macOS ###

最低支持版本 macOS 26.0 Intel + Apple Silicon

Support for macOS 26, Intel and Silicon hosts.

<img src="Assets/截屏2026-06-28 02.28.40.png" alt="截屏2026-06-28 02.28.40" style="zoom:50%;" />

支持中英文切换 (选项-语言-中/英文)

U can change language whether u want. (SimpCHN or enUS)

<img src="Assets/截屏2026-06-25 01.30.38.png" alt="1" style="zoom:50%;" />

主要特征： 深色浅色自动切换 以及和Windows 10 任务管理器几乎一致的界面和交互。

Main features: automatic switching between dark and light modes, and an interface and interactions almost identical to Windows 10 Task Manager.

<img src="Assets/截屏2026-06-28 02.22.58.png" alt="截屏2026-06-28 02.22.58" style="zoom:50%;" />

技术实现路径：

- NPU / ANE：当前已从早期 heuristic 估算，改为基于私有 `IOReport` 的实测链路。主要读取 `Energy Model`、`ANS2 Power`、`AMC Stats Perf Counters`，用于生成功耗、活跃度、数据搬运等图形。
- 散热：新增独立 `散热` 页面，风扇转速主要来自 `AppleSMC`，温度则结合 `SMC`、HID 温度节点以及板级传感器映射，覆盖 CPU、GPU、磁盘、网卡、SoC、主板、电源与外壳等项目。

Implementation notes:

- NPU / ANE: the old heuristic path has been replaced by a private `IOReport`-based pipeline. It mainly reads from `Energy Model`, `ANS2 Power`, and `AMC Stats Perf Counters` to drive Power, Activity, and Data Movement graphs.
- Thermal: a dedicated `Thermal` page has been added. Fan RPM mainly comes from `AppleSMC`, while temperatures are collected through `SMC`, HID temperature nodes, and board-level sensor mappings for CPU, GPU, disk, Wi-Fi, SoC, logic board, power, and enclosure.

<img src="Assets/截屏2026-06-28 02.24.08.png" alt="截屏2026-06-28 02.24.08" style="zoom:50%;" />

<img src="Assets/截屏2026-06-28 02.25.22.png" alt="截屏2026-06-28 02.25.22" style="zoom:50%;" />

最后，这只是一个初始工程，不打算一直更新。

At last, I did it just for fun. I don't promise to keep releasing updated versions.

**部分代码由AI生成，如果您认为涉及抄袭或者剽窃，请直接提issues。** 

**Some of the code is AI-generated. If you think it involves plagiarism or copying, just write an issue.**
