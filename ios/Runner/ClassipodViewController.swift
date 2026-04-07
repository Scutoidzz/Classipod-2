import Flutter
import UIKit

final class ClassipodViewController: FlutterViewController {
  private var immersiveModeEnabled = false
  private var systemUiChannel: FlutterMethodChannel?

  override var prefersStatusBarHidden: Bool {
    immersiveModeEnabled
  }

  override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
    .fade
  }

  override var prefersHomeIndicatorAutoHidden: Bool {
    immersiveModeEnabled
  }

  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
    immersiveModeEnabled ? .all : []
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    systemUiChannel = FlutterMethodChannel(
      name: "classipod/system_ui",
      binaryMessenger: binaryMessenger
    )
    systemUiChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setImmersiveMode" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let enabled = arguments["enabled"] as? Bool
      else {
        result(
          FlutterError(
            code: "bad-args",
            message: "Expected a boolean immersive mode flag.",
            details: nil
          )
        )
        return
      }

      self?.updateImmersiveMode(enabled)
      result(nil)
    }
  }

  private func updateImmersiveMode(_ enabled: Bool) {
    immersiveModeEnabled = enabled
    setNeedsStatusBarAppearanceUpdate()
    setNeedsUpdateOfHomeIndicatorAutoHidden()
    setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
  }
}
