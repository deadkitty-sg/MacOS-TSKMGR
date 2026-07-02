import SwiftUI
import AppKit

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese
    case english

    var id: String { rawValue }

    var isChinese: Bool { self == .chinese }

    func text(_ chinese: String, _ english: String) -> String {
        isChinese ? chinese : english
    }

    func translateImpact(_ value: String) -> String {
        switch value {
        case "非常高": return "Very high"
        case "高": return "High"
        case "中": return "Moderate"
        case "低": return "Low"
        case "非常低": return "Very low"
        default: return value
        }
    }

    func localizeImpact(_ value: String) -> String {
        if isChinese {
            switch value {
            case "Very high": return "非常高"
            case "High": return "高"
            case "Moderate": return "中"
            case "Low": return "低"
            case "Very low": return "非常低"
            default: return value
            }
        }
        return translateImpact(value)
    }

    func translateProcessSectionTitle(_ title: String) -> String {
        guard !isChinese else { return title }
        if title.hasPrefix("应用 (") {
            return title.replacingOccurrences(of: "应用", with: "Apps")
        }
        if title.hasPrefix("后台进程 (") {
            return title.replacingOccurrences(of: "后台进程", with: "Background")
        }
        return title
    }

    func translateStartupStatus(_ value: String) -> String {
        switch value {
        case "已启用": return "Enabled"
        case "已禁用": return "Disabled"
        default: return value
        }
    }

    func localizeStartupStatus(_ value: String) -> String {
        if isChinese {
            switch value {
            case "Enabled": return "已启用"
            case "Disabled": return "已禁用"
            default: return value
            }
        }
        return translateStartupStatus(value)
    }

    func translateStartupImpact(_ value: String) -> String {
        switch value {
        case "高": return "High"
        case "未计算": return "N/A"
        default: return translateImpact(value)
        }
    }

    func localizeStartupImpact(_ value: String) -> String {
        if isChinese {
            switch value {
            case "High": return "高"
            case "N/A": return "未计算"
            default: return localizeImpact(value)
            }
        }
        return translateStartupImpact(value)
    }

    func translateDirectoryLabel(_ value: String) -> String {
        switch value {
        case "登录项": return "Login item"
        case "系统守护进程": return "System daemon"
        case "系统代理": return "System agent"
        case "用户代理": return "User agent"
        default: return value
        }
    }

    func localizeDirectoryLabel(_ value: String) -> String {
        if isChinese {
            switch value {
            case "Login item": return "登录项"
            case "System daemon": return "系统守护进程"
            case "System agent": return "系统代理"
            case "User agent": return "用户代理"
            default: return value
            }
        }
        return translateDirectoryLabel(value)
    }

    func translateServiceStatus(_ value: String) -> String {
        switch value {
        case "正在运行": return "Running"
        case "按需": return "On demand"
        case "已加载": return "Loaded"
        case "已停止": return "Stopped"
        case "未加载": return "Not loaded"
        case "已禁用": return "Disabled"
        default: return value
        }
    }

    func localizeServiceStatus(_ value: String) -> String {
        if isChinese {
            switch value {
            case "Running": return "正在运行"
            case "On demand": return "按需"
            case "Loaded": return "已加载"
            case "Stopped": return "已停止"
            case "Not loaded": return "未加载"
            case "Disabled": return "已禁用"
            default: return value
            }
        }
        return translateServiceStatus(value)
    }

    func translateProcessStatus(_ value: String) -> String {
        switch value {
        case "正在创建": return "Starting"
        case "正在运行": return "Running"
        case "正在睡眠": return "Sleeping"
        case "已停止": return "Stopped"
        case "僵尸": return "Zombie"
        case "未知": return "Unknown"
        default: return value
        }
    }

    func localizeProcessStatus(_ value: String) -> String {
        if isChinese {
            switch value {
            case "Starting": return "正在创建"
            case "Running": return "正在运行"
            case "Sleeping": return "正在睡眠"
            case "Stopped": return "已停止"
            case "Zombie": return "僵尸"
            case "Unknown": return "未知"
            default: return value
            }
        }
        return translateProcessStatus(value)
    }

    func translatePlatform(_ value: String) -> String {
        switch value {
        case "64位": return "64-bit"
        case "32位": return "32-bit"
        default: return value
        }
    }

    func localizePlatform(_ value: String) -> String {
        if isChinese {
            switch value {
            case "64-bit": return "64位"
            case "32-bit": return "32位"
            default: return value
            }
        }
        return translatePlatform(value)
    }

    func translateDiskKind(_ value: String) -> String {
        switch value {
        case "可移动": return "Removable"
        case "内建": return "Internal"
        case "外建": return "External"
        default: return value
        }
    }

    func localizeDiskKind(_ value: String) -> String {
        if isChinese {
            switch value {
            case "Removable": return "可移动"
            case "Internal": return "内建"
            case "External": return "外建"
            default: return value
            }
        }
        return translateDiskKind(value)
    }

    func translateNetworkMedium(_ value: String) -> String {
        switch value {
        case "以太网": return "Ethernet"
        case "VPN隧道": return "VPN tunnel"
        case "虚拟网络": return "Virtual network"
        case "网络接口": return "Network interface"
        default: return value
        }
    }

    func localizeNetworkMedium(_ value: String) -> String {
        if isChinese {
            switch value {
            case "Ethernet": return "以太网"
            case "VPN tunnel": return "VPN隧道"
            case "Virtual network": return "虚拟网络"
            case "Network interface": return "网络接口"
            case "Virtual": return "虚拟"
            default: return value
            }
        }
        return translateNetworkMedium(value)
    }

    func translateDiskTitle(_ value: String) -> String {
        guard !isChinese else { return value }
        if value.hasPrefix("磁盘 ") {
            return value.replacingOccurrences(of: "磁盘", with: "Disk")
        }
        return value
    }

    func localizeDiskTitle(_ value: String) -> String {
        if isChinese {
            if value.hasPrefix("Disk ") {
                return value.replacingOccurrences(of: "Disk", with: "磁盘")
            }
            return value
        }
        return translateDiskTitle(value)
    }

    func localizeRuntimeMessage(_ value: String) -> String {
        if isChinese {
            switch value {
            case "Unable to end this task.": return "不能结束该任务。"
            case "Unable to end Task Manager itself.": return "不能结束当前任务管理器自身。"
            case "Permission denied. Unable to end this task.": return "权限不足，无法结束该任务。"
            case "Invalid end-task request.": return "结束任务请求无效。"
            case "This task no longer exists.": return "该任务已不存在。"
            case "Incorrect password.": return "密码不正确。"
            case "Task execution failed.": return "任务执行失败。"
            case "Unable to open application.": return "无法打开应用程序。"
            case "Unable to change the process priority.": return "无法更改进程优先级。"
            default:
                if value.hasPrefix("Unable to start task: ") {
                    return value.replacingOccurrences(of: "Unable to start task:", with: "无法启动任务：")
                }
                return value
            }
        }
        return value
    }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius
    case fahrenheit

    var id: String { rawValue }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .celsius:
            return language.text("摄氏度°C", "Celsius °C")
        case .fahrenheit:
            return language.text("华氏度°F", "Fahrenheit °F")
        }
    }

    func format(_ celsius: Double?) -> String {
        guard let celsius else { return "--" }
        switch self {
        case .celsius:
            return String(format: "%.1f °C", celsius)
        case .fahrenheit:
            return String(format: "%.1f °F", celsius * 9.0 / 5.0 + 32.0)
        }
    }
}

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .chinese
}

private struct TemperatureUnitKey: EnvironmentKey {
    static let defaultValue: TemperatureUnit = .celsius
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }

    var temperatureUnit: TemperatureUnit {
        get { self[TemperatureUnitKey.self] }
        set { self[TemperatureUnitKey.self] = newValue }
    }
}

enum TaskTab: String, CaseIterable, Identifiable {
    case processes
    case performance
    case history
    case startup
    case users
    case details
    case services

    var id: String { rawValue }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .processes: language.text("进程", "Processes")
        case .performance: language.text("性能", "Performance")
        case .history: language.text("应用历史记录", "App history")
        case .startup: language.text("启动", "Startup")
        case .users: language.text("用户", "Users")
        case .details: language.text("详细信息", "Details")
        case .services: language.text("服务", "Services")
        }
    }
}

enum RefreshSpeedOption: String, CaseIterable, Identifiable {
    case high
    case normal
    case low
    case paused

    var id: String { rawValue }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .high: language.text("高(H)", "High(H)")
        case .normal: language.text("正常(N)", "Normal(N)")
        case .low: language.text("低(L)", "Low(L)")
        case .paused: language.text("已暂停(P)", "Paused(P)")
        }
    }

    var interval: TimeInterval? {
        switch self {
        case .high: 0.5
        case .normal: 1.0
        case .low: 2.5
        case .paused: nil
        }
    }
}

enum ProcessSortKey: String {
    case name
    case status
    case cpu
    case memory
    case disk
    case network
    case power
    case trend
}

enum ProcessResourceDisplayMode {
    case value
    case percent
}

enum ProcessPriorityPreset: CaseIterable {
    case veryLow
    case low
    case normal
    case high
    case realtime

    var niceValue: Int32 {
        switch self {
        case .veryLow: 20
        case .low: 10
        case .normal: 0
        case .high: -5
        case .realtime: -10
        }
    }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .veryLow: language.text("低", "Low")
        case .low: language.text("低于正常", "Below normal")
        case .normal: language.text("正常", "Normal")
        case .high: language.text("高于正常", "Above normal")
        case .realtime: language.text("高", "High")
        }
    }
}

enum PerfSelection: Hashable, Identifiable {
    case cpu
    case memory
    case disk(String)
    case network(String)
    case npu(String)
    case gpu(String)
    case thermal
    case battery

    var id: String {
        switch self {
        case .cpu:
            "cpu"
        case .memory:
            "memory"
        case .disk(let diskID):
            "disk-\(diskID)"
        case .network(let interface):
            "network-\(interface)"
        case .npu(let npuID):
            "npu-\(npuID)"
        case .gpu(let gpuID):
            "gpu-\(gpuID)"
        case .thermal:
            "thermal"
        case .battery:
            "battery"
        }
    }
}

enum PerformanceViewMode: String {
    case full
    case summary
    case detailSummary
}

enum CPUGraphMode {
    case logicalProcessors
    case overallUtilization
}

enum GPUGraphLayoutMode {
    case singleEngine
    case multiEngine
}

enum NPUGraphLayoutMode {
    case singleEngine
    case multiEngine
}

enum GPUGraphKind: String, CaseIterable, Identifiable {
    case overall = "Overall"
    case threeD = "3D"
    case tilerCopy = "Tiler"

    var id: String { rawValue }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .overall: language.text("总体", "Overall")
        case .threeD: "3D"
        case .tilerCopy: language.text("Tiler/Copy", "Tiler/Copy")
        }
    }
}

enum NPUGraphKind: String, CaseIterable, Identifiable {
    case active = "Active"
    case power = "Power"
    case dataMovement = "Data"
    case memory = "Memory"

    var id: String { rawValue }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .active:
            return language.text("活跃度", "Activity")
        case .power:
            return language.text("功耗", "Power")
        case .dataMovement:
            return language.text("数据搬运", "Data movement")
        case .memory:
            return language.text("共享内存", "Shared memory")
        }
    }
}

struct ProcessRowData: Identifiable, Equatable {
    let pid: Int32
    let name: String
    let icon: NSImage?
    let path: String
    let isApp: Bool
    let isParent: Bool
    let parentPID: Int32?
    let childCount: Int
    let cpuPercent: Double
    let memoryBytes: UInt64
    let diskBytesPerSecond: UInt64
    let networkBytesPerSecond: UInt64
    let networkText: String
    let powerUsageWatts: Double
    let powerTrendWatts: Double
    let powerImpact: String
    let trend: String
    let threadCount: Int
    let openFiles: Int

    var id: Int32 { pid }
}

struct ProcessSectionData: Identifiable, Equatable {
    let title: String
    let rows: [ProcessRowData]
    // Identity must be stable across refresh ticks (titles are unique), otherwise
    // SwiftUI tears down and rebuilds every section subtree on each tick.
    var id: String { title }
}

struct UserPageSectionData: Identifiable, Equatable {
    let userName: String
    let rows: [ProcessRowData]
    var id: String { userName }
}

struct AppHistoryRowData: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: NSImage?
    let path: String
    let cpuTime: String
    let cpuSeconds: Double
    let network: String
    let networkBytes: UInt64
    let meteredNetwork: String
    let meteredNetworkBytes: UInt64
}

/// Typed launchd service state. Program logic (sorting, start/stop gating) keys
/// off this enum; localization is a pure `displayTitle(in:)` presentation concern
/// so a wording change or a new language can never break behavior.
enum ServiceStatus: Equatable {
    case running
    case onDemand
    case loaded
    case stopped
    case notLoaded
    case disabled
    case unknown

    /// Parse the canonical status string emitted by the launchd probe (English),
    /// tolerating an already-localized Chinese value defensively.
    init(canonical raw: String) {
        switch raw {
        case "Running", "正在运行": self = .running
        case "On demand", "按需": self = .onDemand
        case "Loaded", "已加载": self = .loaded
        case "Stopped", "已停止": self = .stopped
        case "Not loaded", "未加载": self = .notLoaded
        case "Disabled", "已禁用": self = .disabled
        default: self = .unknown
        }
    }

    var sortRank: Int {
        switch self {
        case .running: 0
        case .onDemand: 1
        case .loaded: 2
        case .stopped: 3
        case .notLoaded: 4
        case .disabled: 5
        case .unknown: 6
        }
    }

    var canStart: Bool { self == .stopped || self == .notLoaded || self == .disabled }
    var canStop: Bool { self == .running || self == .onDemand || self == .loaded }
    var canRestart: Bool { self == .running }

    func displayTitle(in language: AppLanguage) -> String {
        switch self {
        case .running: language.text("正在运行", "Running")
        case .onDemand: language.text("按需", "On demand")
        case .loaded: language.text("已加载", "Loaded")
        case .stopped: language.text("已停止", "Stopped")
        case .notLoaded: language.text("未加载", "Not loaded")
        case .disabled: language.text("已禁用", "Disabled")
        case .unknown: language.text("未知", "Unknown")
        }
    }
}

/// Typed launchd startup-item state (enabled/disabled).
enum StartupState: Equatable {
    case enabled
    case disabled
    case unknown

    init(canonical raw: String) {
        switch raw {
        case "Enabled", "已启用": self = .enabled
        case "Disabled", "已禁用": self = .disabled
        default: self = .unknown
        }
    }

    func displayTitle(in language: AppLanguage) -> String {
        switch self {
        case .enabled: language.text("已启用", "Enabled")
        case .disabled: language.text("已禁用", "Disabled")
        case .unknown: language.text("未知", "Unknown")
        }
    }
}

struct StartupItemRowData: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: NSImage?
    let publisher: String
    let status: StartupState
    let startupImpact: String
}

struct ServiceRowData: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: NSImage?
    let pid: Int32?
    let serviceDescription: String
    let status: ServiceStatus
    let group: String
    let label: String
}

struct DetailProcessRowData: Identifiable, Equatable {
    let id: Int32
    let name: String
    let icon: NSImage?
    let pid: Int32
    let status: String
    let userName: String
    let cpuPercent: Double
    let memoryBytes: UInt64
    let platform: String
}

enum AppleSiliconCoreTierMode {
    case performanceEfficiency
    case superPerformance
    case superEfficiency
    case genericPrimarySecondary
    case singlePerformanceTier
}

struct CPUState {
    var modelName: String = "Apple Silicon"
    var utilizationPercent: Double = 0
    var speedText: String = "--"
    var baseSpeedText: String = "--"
    var performanceCoreSpeedText: String = "--"
    var efficiencyCoreSpeedText: String = "--"
    var coreTierMode: AppleSiliconCoreTierMode = .singlePerformanceTier
    var logicalCores: Int = 0
    var physicalCores: Int = 0
    var processCount: Int = 0
    var threadCount: Int = 0
    var openFilesCount: Int = 0
    var uptimeText: String = "0:00:00:00"
    var history: [Double] = Array(repeating: 0, count: 60)
    var coreHistories: [[Double]] = []
}

/// Kernel memory-pressure level from `kern.memorystatus_vm_pressure_level`
/// (1 = normal, 2 = warning, 4 = critical).
enum MemoryPressureLevel: Equatable {
    case normal
    case warning
    case critical
    case unknown

    init(sysctlValue: Int) {
        switch sysctlValue {
        case 1: self = .normal
        case 2: self = .warning
        case 4: self = .critical
        default: self = .unknown
        }
    }

    func displayTitle(in language: AppLanguage) -> String {
        switch self {
        case .normal: language.text("正常", "Normal")
        case .warning: language.text("警告", "Warning")
        case .critical: language.text("严重", "Critical")
        case .unknown: "--"
        }
    }
}

struct MemoryState {
    var totalBytes: UInt64 = 0
    var usedBytes: UInt64 = 0
    var availableBytes: UInt64 = 0
    var compressedBytes: UInt64 = 0
    var cachedBytes: UInt64 = 0
    var swapUsedBytes: UInt64 = 0
    var appMemoryBytes: UInt64 = 0
    var wiredBytes: UInt64 = 0
    var pressureLevel: MemoryPressureLevel = .unknown
    var loadAverage1: Double = 0
    var loadAverage5: Double = 0
    var loadAverage15: Double = 0
    var swapInsPerSecond: Double = 0
    var swapOutsPerSecond: Double = 0
    var historyPercent: [Double] = Array(repeating: 0, count: 60)
    var historyUsedBytes: [Double] = Array(repeating: 0, count: 60)
    var chartCeilingBytes: Double = 1
}

struct DiskState: Identifiable {
    let id: String
    var title: String
    var subtitle: String
    var kindLabel: String
    var modelName: String
    var capacityBytes: UInt64
    var availableBytes: UInt64
    var isSystemDisk: Bool
    var activityPercent: Double
    var responseTimeMs: Double
    var readBytesPerSecond: UInt64
    var writeBytesPerSecond: UInt64
    var activityHistory: [Double]
    var readHistory: [Double]
    var writeHistory: [Double]
    var transferHistory: [Double]
    var transferChartCeilingBytesPerSecond: Double
}

struct NetworkState: Identifiable {
    let id: String
    var displayName: String
    var subtitle: String
    var interfaceName: String
    var ipv4: String
    var ipv6: String
    var sendBytesPerSecond: UInt64
    var receiveBytesPerSecond: UInt64
    var totalSendBytes: UInt64
    var totalReceiveBytes: UInt64
    var packetsSent: UInt64
    var packetsReceived: UInt64
    var multicastSent: UInt64
    var multicastReceived: UInt64
    var errorsIn: UInt64
    var errorsOut: UInt64
    var dropsIn: UInt64
    var dropsOut: UInt64
    var mtu: UInt32
    var linkSpeedBitsPerSecond: UInt64
    var linkSpeedText: String
    var statusText: String
    var totalHistory: [Double]
    var detailHistory: [Double]
    var sendHistory: [Double]
    var receiveHistory: [Double]
    var chartCeilingBytesPerSecond: Double
}

struct GPUState: Identifiable {
    let id: String
    var title: String
    var subtitle: String
    var modelName: String
    var gpuCount: Int
    var gpuType: String
    var coreCount: Int
    var utilizationPercent: Double
    var rendererUtilizationPercent: Double
    var tilerUtilizationPercent: Double
    var sharedMemoryUsedBytes: UInt64
    var sharedMemoryAllocatedBytes: UInt64
    var metalVersion: String
    var openGLVersion: String?
    var historyOverall: [Double]
    var history3D: [Double]
    var historyTiler: [Double]
    var memoryHistory: [Double]
}

struct NPUState: Identifiable {
    let id: String
    var title: String
    var subtitle: String
    var modelName: String
    var npuCount: Int
    var coreCount: Int
    var architecture: String
    var firmwareLoaded: Bool
    var currentPowerState: Int
    var maxPowerState: Int
    var activeClientCount: Int
    var activeTimePercent: Double
    var powerWatts: Double
    var peakPowerWatts: Double
    var dataReadBytesPerSecond: UInt64
    var dataWriteBytesPerSecond: UInt64
    var dataMovementBytesPerSecond: UInt64
    var peakDataMovementBytesPerSecond: UInt64
    var neuralFootprintBytes: UInt64
    var peakNeuralFootprintBytes: UInt64
    var historyActiveTime: [Double]
    var historyPowerWatts: [Double]
    var historyDataMovementBytes: [Double]
    var historyFootprint: [Double]
    var historyMemoryPressure: [Double]
}

struct BatteryState: Equatable {
    var isPresent: Bool = false
    var chargePercent: Double = 0
    var isCharging: Bool = false
    var onACPower: Bool = false
    /// Minutes to empty (on battery) or to full (charging); nil while the
    /// power-management estimate is still being calculated.
    var timeRemainingMinutes: Int? = nil
    var cycleCount: Int? = nil
    var healthPercent: Double? = nil
    var temperatureCelsius: Double? = nil
    var adapterWatts: Double? = nil
    var historyChargePercent: [Double] = Array(repeating: 0, count: 60)
}

struct ThermalState {
    var title: String = "Cooling"
    var subtitle: String = "--"
    var statusText: String = "--"
    var currentFanRPM: UInt32 = 0
    var peakFanRPM: UInt32 = 0
    var maximumFanRPM: UInt32 = 6000
    var cpuTemperatureCelsius: Double? = nil
    var efficiencyCoreTemperatureCelsius: Double? = nil
    var performanceCoreTemperatureCelsius: Double? = nil
    var gpuTemperatureCelsius: Double? = nil
    var diskTemperatureCelsius: Double? = nil
    var networkTemperatureCelsius: Double? = nil
    var logicBoardTemperatureCelsius: Double? = nil
    var socTemperatureCelsius: Double? = nil
    var powerSupplyTemperatureCelsius: Double? = nil
    var powerSurfaceTemperatureCelsius: Double? = nil
    var enclosureTemperatureCelsius: Double? = nil
    var systemTemperatureCelsius: Double? = nil
    var historyFanRPM: [Double] = Array(repeating: 0, count: 60)
    var fanChartCeilingRPM: Double = 1000
    var historyNetworkTemperatureCelsius: [Double] = Array(repeating: 0, count: 60)
    var networkTemperatureChartCeilingCelsius: Double = 50
}

struct PerfSidebarItem: Identifiable, Equatable {
    let id: PerfSelection
    let title: String
    let subtitle: String
    let tertiary: String?
    let accent: Color
    let sparkline: [Double]
    let selectedFill: Color
}

struct DetailMetric: Identifiable {
    let label: String
    let value: String
    var prominent: Bool = false
    let id = UUID()
}

struct InfoPair: Identifiable {
    let label: String
    let value: String
    let id = UUID()
}

enum DisplayFormat {
    static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }

    static func percentWithPrecision(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.\(digits)f%%", value)
    }

    static func frequency(_ hz: UInt64?) -> String {
        guard let hz, hz > 0 else { return "--" }
        return String(format: "%.2f GHz", Double(hz) / 1_000_000_000)
    }

    static func bytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .binary
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: Int64(bytes))
    }

    static func decimalBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .decimal
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: Int64(bytes))
    }

    static func memory(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        }
        let mb = Double(bytes) / 1_048_576
        return String(format: "%.1f MB", mb)
    }

    static func watts(_ value: Double) -> String {
        if value >= 10 {
            return String(format: "%.1f W", value)
        }
        return String(format: "%.2f W", value)
    }

    static func throughput(_ bytesPerSecond: UInt64) -> String {
        if bytesPerSecond == 0 {
            return "0 KB/s"
        }
        let kb = Double(bytesPerSecond) / 1024
        if kb < 1024 {
            return String(format: "%.1f KB/s", kb)
        }
        let mb = kb / 1024
        return String(format: "%.1f MB/s", mb)
    }

    static func networkRate(_ bytesPerSecond: UInt64) -> String {
        if bytesPerSecond == 0 {
            return "0 Kbps"
        }
        let kilobits = Double(bytesPerSecond) * 8 / 1000
        if kilobits < 1000 {
            return String(format: "%.1f Kbps", kilobits)
        }
        return String(format: "%.2f Mbps", kilobits / 1000)
    }

    static func linkSpeed(bitsPerSecond: UInt64) -> String {
        guard bitsPerSecond > 0 else { return "--" }
        let megabits = Double(bitsPerSecond) / 1_000_000
        if megabits < 1000 {
            return String(format: "%.1f Mbps", megabits)
        }
        let gigabits = megabits / 1000
        return String(format: "%.1f Gbps", gigabits)
    }

    static func uptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let days = total / 86_400
        let hours = (total % 86_400) / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%d:%02d:%02d:%02d", days, hours, minutes, secs)
    }

    static func impactLabel(cpuPercent: Double) -> String {
        switch cpuPercent {
        case 30...:
            return "非常高"
        case 15..<30:
            return "高"
        case 5..<15:
            return "中"
        case 1..<5:
            return "低"
        default:
            return "非常低"
        }
    }

    static func impactLabel(cpuPercent: Double, language: AppLanguage) -> String {
        language.translateImpact(impactLabel(cpuPercent: cpuPercent))
    }

    static func impactLabel(powerUsageWatts: Double, wakeupsPerSecond: Double, language: AppLanguage) -> String {
        let score = powerUsageWatts * 1000.0 + wakeupsPerSecond * 0.6
        let label: String
        switch score {
        case 120...:
            label = "非常高"
        case 45..<120:
            label = "高"
        case 12..<45:
            label = "中"
        case 2.5..<12:
            label = "低"
        default:
            label = "非常低"
        }
        return language.translateImpact(label)
    }
}
