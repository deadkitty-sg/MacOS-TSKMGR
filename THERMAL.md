# Cooling / Thermal Notes

散热页面用于展示当前机器的风扇与温度状态。它不是单纯的风扇转速页，而是尽量把 CPU、GPU、磁盘、网卡、SoC、主板、电源与外壳等温度整合到一个持续刷新的性能页面里。

The Cooling page is used to show the current fan and temperature state of the machine. It is not just a fan-RPM page. The goal is to bring CPU, GPU, disk, Wi-Fi, SoC, logic board, power, and enclosure temperatures into one continuously refreshed performance page.

## 当前状态 / Current Status

当前页面已经支持独立侧边栏条目、独立详情页、有风扇与无风扇机型分流逻辑，以及主图、状态区和温度区的拆分展示。有风扇机型主图显示风扇转速，无风扇机型则改为显示网卡温度曲线。

The page already supports its own sidebar entry, its own detail page, different behavior for fan-equipped and fanless machines, and separate graph, status, and temperature sections. On fan-equipped machines the main graph shows fan RPM, while on fanless machines it falls back to the Wi-Fi temperature curve.

## 数据来源 / Data Sources

风扇主要来自 `AppleSMC`，温度则综合 `SMC`、HID 温度节点以及板级传感器映射。当前覆盖 CPU、GPU、磁盘、网卡、SoC、逻辑板、电源表面、外壳等项目，并会对可用温度做整机平均。

Fan data mainly comes from `AppleSMC`, while temperatures are combined from `SMC`, HID temperature nodes, and board-level sensor mappings. The current implementation covers CPU, GPU, disk, Wi-Fi, SoC, logic board, power surface, enclosure, and also derives a whole-system average from available readings.

## 已知映射 / Known Mappings

当前维护中比较高置信度的映射包括：

- `Airport Wireless -> TW0P`
- `Logic Board -> TH0a / TH0x`
- `SoC -> TSCD`
- `Power Supply -> TPD0`
- `Power Surface -> TCMb`
- `Enclosure -> Tm0p / Tm2p`

The current maintenance work treats the following mappings as relatively high-confidence:

- `Airport Wireless -> TW0P`
- `Logic Board -> TH0a / TH0x`
- `SoC -> TSCD`
- `Power Supply -> TPD0`
- `Power Surface -> TCMb`
- `Enclosure -> Tm0p / Tm2p`

## 已知局限 / Known Limitations

这些温度来源和板级映射并不是 Apple 官方公开定义，因此未来系统版本、不同板型或者新芯片代际都可能要求重新验证。页面更适合被理解成“实用型硬件观测页”，而不是一个完全官方、长期稳定的传感器标准实现。

These temperature sources and board-level mappings are not publicly documented by Apple, so future macOS releases, different board layouts, or new chip generations may require revalidation. The page is best understood as a practical hardware-observation view, not as a fully official long-term stable sensor standard.

## 关键文件 / Key Files

- [SystemMonitor.swift](Sources/MacOSTSKMGR/SystemMonitor.swift)
- [PerformancePageView.swift](Sources/MacOSTSKMGR/PerformancePageView.swift)
- [Models.swift](Sources/MacOSTSKMGR/Models.swift)

## 后续建议 / Next Steps

后续维护建议优先继续验证传感器映射准确性、不同机型下的主图选择，以及页面术语与展示顺序的一致性。

For future maintenance, the most useful next steps are validating sensor mappings, confirming graph selection behavior across machine types, and keeping page terminology and layout order consistent.
