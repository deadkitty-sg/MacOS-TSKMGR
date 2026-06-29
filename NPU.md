# NPU / ANE Notes

NPU / ANE 页面目前的重点是把早期的启发式估算，逐步替换成更接近真实硬件行为的采样链路。当前实现主要依赖私有 `IOReport`，结合 `Energy Model`、`ANS2 Power` 与 `AMC Stats Perf Counters`，用于生成功耗、活跃度、数据搬运和共享内存相关图形。

The current focus of the NPU / ANE page is to move away from early heuristic estimation and toward a pipeline that is closer to real hardware behavior. The implementation mainly relies on private `IOReport`, together with `Energy Model`, `ANS2 Power`, and `AMC Stats Perf Counters`, to drive power, activity, data movement, and shared-memory visuals.

## 当前状态 / Current Status

当前页面主要围绕四类图形工作：`Active`、`Power`、`Data movement`、`Memory`。其中 `Power` 的链路最稳，`Active` 已经替代旧的主 heuristic 方向，`Data movement` 与 `Memory` 也都已接入，但仍然需要继续在真实负载下观察波形和尺度。

The page currently revolves around four graph types: `Active`, `Power`, `Data movement`, and `Memory`. Among them, `Power` is the most stable, `Active` has already replaced the old primary heuristic direction, and both `Data movement` and `Memory` are connected, but they still need more validation under real workloads.

## 关键说明 / Key Notes

早期版本里存在一条带固定基线的 `Compute` 估算逻辑，它更像“显示层起步偏置”，而不是真实利用率。当前版本已经尽量减少这类模拟值，优先展示来自采样链路的结果，但这部分仍然不是 Apple 官方公开 API 的稳定口径。

Earlier versions included a `Compute` estimate with a fixed baseline. It behaved more like a display-level bias than a true utilization metric. The current version tries to minimize such simulated values and prefers measured data from the sampling pipeline, but this still should not be treated as an official public Apple API metric.

## 已知局限 / Known Limitations

NPU / ANE 相关实现依赖私有接口，因此未来系统更新、芯片代际变化或不同机型之间，都可能需要重新校准。尤其是 `Active` 的尺度、`Data movement` 的解释方式，以及共享内存的展示语义，都属于需要持续验证的部分。

The NPU / ANE implementation depends on private interfaces, so future macOS updates, new chip generations, or different machine families may require recalibration. In particular, the scaling of `Active`, the interpretation of `Data movement`, and the display semantics of shared memory should all be treated as areas that require ongoing validation.

## 关键文件 / Key Files

- [SystemMonitor.swift](Sources/MacOSTSKMGR/SystemMonitor.swift)
- [Models.swift](Sources/MacOSTSKMGR/Models.swift)
- [PerformancePageView.swift](Sources/MacOSTSKMGR/PerformancePageView.swift)

## 后续建议 / Next Steps

后续维护建议优先关注三件事：`Active` 的尺度校准、`Data movement` 在真实推理负载下的验证，以及页面展示细节的收尾。

For future maintenance, the three best priorities are calibrating `Active`, validating `Data movement` under real inference workloads, and polishing the remaining display details.
