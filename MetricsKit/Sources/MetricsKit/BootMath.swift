import Foundation

public enum BootMath {
    /// Boot-to-login duration from `kern.boottime` and loginwindow's start
    /// timestamp (both epoch seconds). Returns nil when the pair is
    /// implausible — clock skew putting login before boot, or a "boot" that
    /// supposedly took over an hour — so callers hide the stat instead of
    /// showing a fabricated number.
    public static func bootToLoginDurationSeconds(bootTime: Double, loginwindowStart: Double) -> Double? {
        let duration = loginwindowStart - bootTime
        guard duration > 0, duration < 3600 else { return nil }
        return duration
    }
}
