import Foundation

/// One JSON object per line, appended when a session ends. Nothing reads it yet — the
/// point is to live with the numbers for a week before deciding which earn a row in the
/// panel. `jq -s` over the file answers every question in the meantime.
public enum SessionLog {
    /// `cacheDir` already ends in SoundBar; appending it again buried the file one level
    /// deeper than every jq recipe looks.
    public static let url = cacheDir.appendingPathComponent("sessions.jsonl")

    private static let stamp = ISO8601DateFormatter()

    public static func line(_ log: AttentionLog,
                            start: Date,
                            end: Date,
                            planned: Int,
                            targets: Int,
                            mode: String,
                            preset: String?,
                            nudges: Int,
                            peeks: Int,
                            ended: String) -> [String: Any] {
        var out: [String: Any] = [
            "start": stamp.string(from: start),
            "end": stamp.string(from: end),
            "planned": planned * 60,
            "actual": round(end.timeIntervalSince(start)),
            "on_target": round(log.onTarget),
            "away": round(log.away),
            "switches": log.switches,
            "longest": round(log.longest),
            "nudges": nudges,
            "peeks": peeks,
            "targets": targets,
            "mode": mode,
            "ended": ended,
            "apps": log.apps.mapValues { ["count": $0.count, "seconds": round($0.seconds)] },
        ]
        if let preset { out["preset"] = preset }
        if let first = log.firstDrift { out["first_drift"] = round(first) }
        return out
    }

    /// Best effort: losing a line is not worth interrupting a stop, and the file is a
    /// notebook, not a ledger.
    public static func append(_ fields: [String: Any], to file: URL = url) {
        guard let data = try? JSONSerialization.data(withJSONObject: fields,
                                                     options: [.sortedKeys]) else { return }
        let line = data + Data("\n".utf8)
        let fm = FileManager.default
        try? fm.createDirectory(at: file.deletingLastPathComponent(),
                                withIntermediateDirectories: true)
        guard let handle = try? FileHandle(forWritingTo: file) else {
            try? line.write(to: file)
            return
        }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: line)
    }
}
