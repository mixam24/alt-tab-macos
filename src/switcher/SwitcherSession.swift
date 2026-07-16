import Cocoa

/// Holds all state scoped to a single switcher invocation: from when the user
/// first triggers the shortcut to when the panel is dismissed.
///
/// `current` is non-nil iff the switcher panel is conceptually shown to the
/// user. Lifetime is owned by `App.showUiOrCycleSelection` (creates) and
/// `App.hideUi` (destroys).
final class SwitcherSession {
    static var current: SwitcherSession?
    static var isActive: Bool { current != nil }
    /// The shortcut index of the currently-active session, or 0 when no session is active.
    /// Used by every per-shortcut effective preference read in `Appearance`, `TileView`, etc.
    static var activeShortcutIndex: Int { current?.shortcutIndex ?? 0 }

    var shortcutIndex: Int = 0
    var isFirstSummon: Bool = true
    var forceDoNothingOnRelease: Bool = false

    var selectedIndex: Int = 0
    var hoveredIndex: Int?
    var selectedTarget: String?
    var searchQuery: String = ""

    /// Full-resolution frames for the Preview panel, fetched just-in-time for the selected window and
    /// its cycling neighbors (`WindowThumbnails.fetchPreviewFrames`, #5861). Living on the session, they
    /// are released wholesale when it ends, so idle RAM only holds thumbnail-scale images. Capped +
    /// least-recently-used-evicted so a long session arrow-keying through many windows stays bounded.
    private static let maxPreviewFrames = 10
    private var previewFrames = [CGWindowID: CALayerContents]()
    private var previewFramesLru = [CGWindowID]() // most recently used last

    func hasPreviewFrame(_ wid: CGWindowID) -> Bool { previewFrames[wid] != nil }

    func previewFrame(_ wid: CGWindowID) -> CALayerContents? {
        guard let frame = previewFrames[wid] else { return nil }
        previewFramesLru.removeAll { $0 == wid }
        previewFramesLru.append(wid)
        return frame
    }

    func storePreviewFrame(_ wid: CGWindowID, _ frame: CALayerContents) {
        previewFrames[wid] = frame
        previewFramesLru.removeAll { $0 == wid }
        previewFramesLru.append(wid)
        if previewFramesLru.count > Self.maxPreviewFrames {
            previewFrames.removeValue(forKey: previewFramesLru.removeFirst())
        }
    }
}
