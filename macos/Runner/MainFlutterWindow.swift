import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Enforce a minimum window size matching a 13" MacBook screen (1440x900).
    // Users cannot shrink the window below this.
    let minSize = NSSize(width: 1440, height: 900)
    self.contentMinSize = minSize
    self.minSize = minSize

    // Ensure the initial window is at least this big.
    if self.frame.size.width < minSize.width || self.frame.size.height < minSize.height {
      var frame = self.frame
      frame.size = NSSize(
        width: max(frame.size.width, minSize.width),
        height: max(frame.size.height, minSize.height)
      )
      self.setFrame(frame, display: true)
      self.center()
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
