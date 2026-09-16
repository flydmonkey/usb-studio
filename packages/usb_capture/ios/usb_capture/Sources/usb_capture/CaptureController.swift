import AVFoundation
import AVKit
import Photos
import UIKit

final class CaptureController: NSObject, AVCaptureFileOutputRecordingDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
  private let emit: ([String: Any]) -> Void
  private let session = AVCaptureSession()
  private let movieOutput = AVCaptureMovieFileOutput()
  private let photoOutput = AVCapturePhotoOutput()
  private let videoOutput = AVCaptureVideoDataOutput()
  private let audioOutput = AVCaptureAudioDataOutput()
  private let audioQueue = DispatchQueue(label: "usb-capture.audio")
  private let videoQueue = DispatchQueue(label: "usb-capture.video")
  private let renderer = AVSampleBufferAudioRenderer()
  private let synchronizer = AVSampleBufferRenderSynchronizer()
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var openedDeviceId: String?
  private var openedDevice: AVCaptureDevice?
  private var hasCaptureAudio = false
  private var previewMuted = false
  private var monitorVolume: Float = 1
  private var qualityPreset = "standard"
  private var recordingURL: URL?
  private var stopHandler: (([String: Any]?, CaptureError?) -> Void)?
  private var snapshotHandler: ((CaptureError?) -> Void)?
  private var lastFrameAt = Date()
  private var gotPreviewFrame = false
  private var frameCount = 0
  private var fpsWindowStart = Date()
  private var measuredFps = 0
  private var lastPeakAt = Date.distantPast
  private var recordingStartedAt: Date?
  private var watchdog: Timer?
  private var pendingClose = false
  private var pendingDisconnect = false
  private var sessionStamp: String?
  private var segmentIndex = 1
  private var rotating = false
  private var rotateTimer: Timer?
  private var sessionStartedAt: Date?
  private var segmentMinutes = 10

  init(emit: @escaping ([String: Any]) -> Void) {
    self.emit = emit
    super.init()
    synchronizer.addRenderer(renderer)
    audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(deviceConnected),
      name: AVCaptureDevice.wasConnectedNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(deviceDisconnected),
      name: AVCaptureDevice.wasDisconnectedNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func attachPreview(_ layer: AVCaptureVideoPreviewLayer) {
    previewLayer = layer
    layer.session = session
    layer.videoGravity = .resizeAspect
    startWatchdog()
  }

  func listDevices() -> [[String: Any]] {
    videoDevices().map { device in
      [
        "id": device.uniqueID,
        "name": device.localizedName,
        "hasAudio": matchingAudioDevice() != nil,
      ]
    }
  }

  func captureStatus() -> [String: Any] {
    let elapsed: Int
    if let started = sessionStartedAt {
      elapsed = Int(Date().timeIntervalSince(started) * 1000)
    } else {
      elapsed = 0
    }
    return [
      "sessionOpen": session.isRunning,
      "recording": movieOutput.isRecording,
      "deviceId": openedDeviceId as Any,
      "segmentIndex": segmentIndex,
      "elapsedMs": elapsed,
      "sessionStamp": sessionStamp as Any,
    ]
  }

  func open(deviceId: String) throws {
    guard UIDevice.current.userInterfaceIdiom == .pad else {
      throw CaptureError.unsupportedPlatform
    }
    if session.isRunning && openedDeviceId == deviceId {
      return
    }
    if movieOutput.isRecording {
      throw CaptureError.recordingFailed
    }
    guard let device = videoDevices().first(where: { $0.uniqueID == deviceId }) else {
      throw CaptureError.uvcFailed
    }
    session.beginConfiguration()
    session.inputs.forEach { session.removeInput($0) }
    session.outputs.forEach { session.removeOutput($0) }
    let videoInput = try AVCaptureDeviceInput(device: device)
    guard session.canAddInput(videoInput) else {
      session.commitConfiguration()
      throw CaptureError.uvcFailed
    }
    session.addInput(videoInput)
    hasCaptureAudio = false
    if let audio = matchingAudioDevice(),
       let audioInput = try? AVCaptureDeviceInput(device: audio),
       session.canAddInput(audioInput) {
      session.addInput(audioInput)
      hasCaptureAudio = true
      if session.canAddOutput(audioOutput) {
        session.addOutput(audioOutput)
      }
    }
    if session.canAddOutput(movieOutput) {
      session.addOutput(movieOutput)
    }
    if session.canAddOutput(photoOutput) {
      session.addOutput(photoOutput)
    }
    if session.canAddOutput(videoOutput) {
      videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
      session.addOutput(videoOutput)
    }
    if let format = preferredFormat(for: device) {
      try? device.lockForConfiguration()
      device.activeFormat = format
      device.unlockForConfiguration()
    }
    session.commitConfiguration()
    openedDeviceId = deviceId
    openedDevice = device
    lastFrameAt = Date()
    gotPreviewFrame = false
    startWatchdog()
    if !hasCaptureAudio {
      emit(["type": "audioUnavailable", "code": "noAudioSource"])
    }
    DispatchQueue.global(qos: .userInitiated).async {
      self.session.startRunning()
    }
  }

  func close() {
    if movieOutput.isRecording {
      pendingClose = true
      movieOutput.stopRecording()
      return
    }
    teardownSession()
  }

  private func teardownSession() {
    stopWatchdog()
    session.stopRunning()
    openedDeviceId = nil
    openedDevice = nil
    hasCaptureAudio = false
    recordingStartedAt = nil
    recordingURL = nil
    pendingClose = false
    pendingDisconnect = false
    rotating = false
    rotateTimer?.invalidate()
    rotateTimer = nil
    sessionStamp = nil
    sessionStartedAt = nil
  }

  func setPreviewMuted(_ muted: Bool) {
    previewMuted = muted
    applyMonitorGain()
  }

  func setMonitorVolume(_ volume: Double) {
    monitorVolume = Float(max(0, min(1, volume)))
    applyMonitorGain()
  }

  func setMonitorDelay(_ delayMs: Int) {
    _ = delayMs
  }

  func setRecordingQuality(_ preset: String) throws {
    if movieOutput.isRecording {
      throw CaptureError.recordingFailed
    }
    switch preset {
    case "tiny", "small", "high":
      qualityPreset = preset
    default:
      qualityPreset = "standard"
    }
  }

  func listFormats() -> [[String: Any]] {
    guard let device = openedDevice else { return [] }
    return device.formats.map { formatMap($0) }
  }

  func setFormat(formatId: String) throws {
    if movieOutput.isRecording {
      throw CaptureError.recordingFailed
    }
    guard session.isRunning, let device = openedDevice else {
      throw CaptureError.noPreview
    }
    guard let format = device.formats.first(where: { self.formatId($0) == formatId }) else {
      throw CaptureError.uvcFailed
    }
    do {
      try device.lockForConfiguration()
      device.activeFormat = format
      device.unlockForConfiguration()
    } catch {
      throw CaptureError.uvcFailed
    }
    emitSignal(hasSignal: true)
  }

  func listPictureControls() -> [[String: Any]] {
    guard let device = openedDevice else { return [] }
    let minBias = device.minExposureTargetBias
    let maxBias = device.maxExposureTargetBias
    guard maxBias > minBias else { return [] }
    let value = Int(((device.exposureTargetBias - minBias) / (maxBias - minBias)) * 100)
    return [[
      "id": "brightness",
      "label": "亮度",
      "min": 0,
      "max": 100,
      "value": value,
      "defaultValue": Int((0 - minBias) / (maxBias - minBias) * 100),
    ]]
  }

  func setPictureControl(id: String, value: Int) {
    guard id == "brightness", let device = openedDevice else { return }
    let minBias = device.minExposureTargetBias
    let maxBias = device.maxExposureTargetBias
    guard maxBias > minBias else { return }
    let bias = minBias + (Float(value) / 100) * (maxBias - minBias)
    try? device.lockForConfiguration()
    device.setExposureTargetBias(bias, completionHandler: nil)
    device.unlockForConfiguration()
  }

  func resetPictureControls() {
    guard let device = openedDevice else { return }
    try? device.lockForConfiguration()
    device.setExposureTargetBias(0, completionHandler: nil)
    device.unlockForConfiguration()
  }

  func takeSnapshot(completion: @escaping (CaptureError?) -> Void) {
    guard session.isRunning else {
      completion(.noPreview)
      return
    }
    snapshotHandler = completion
    photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
  }

  private func applyMonitorGain() {
    renderer.volume = previewMuted ? 0 : monitorVolume
  }

  private func videoBitrate() -> Int {
    let base: Int
    switch qualityPreset {
    case "high":
      base = 16_000_000
    case "small":
      base = 4_000_000
    case "tiny":
      base = 2_000_000
    default:
      base = 8_000_000
    }
    guard let device = openedDevice else { return base }
    let dims = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
    let scale = Double(dims.width * dims.height) / (1920.0 * 1080.0)
    let clamped = min(max(scale, 0.25), 2.0)
    return Int(Double(base) * clamped)
  }

  private func applyRecordingQuality() {
    guard let connection = movieOutput.connection(with: .video) else { return }
    movieOutput.setOutputSettings([
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: videoBitrate(),
      ],
    ], for: connection)
  }

  func startRecording(segmentMinutes: Int = 10) throws {
    guard session.isRunning else {
      throw CaptureError.noPreview
    }
    if movieOutput.isRecording {
      throw CaptureError.recordingFailed
    }
    let allowed = [0, 5, 10, 15, 30]
    self.segmentMinutes = allowed.contains(segmentMinutes) ? segmentMinutes : 10
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    sessionStamp = formatter.string(from: Date())
    segmentIndex = 1
    sessionStartedAt = Date()
    try startCurrentSegment()
    scheduleRotate()
  }

  private func startCurrentSegment() throws {
    guard session.isRunning else {
      throw CaptureError.noPreview
    }
    let stamp = sessionStamp ?? DateFormatter.usbStamp.string(from: Date())
    let name = segmentMinutes > 0
      ? String(format: "USB_%@_%02d.mp4", stamp, segmentIndex)
      : "USB_\(stamp).mp4"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
    recordingURL = url
    recordingStartedAt = Date()
    applyRecordingQuality()
    movieOutput.startRecording(to: url, recordingDelegate: self)
  }

  private func scheduleRotate() {
    rotateTimer?.invalidate()
    guard segmentMinutes > 0 else { return }
    rotateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(segmentMinutes * 60), repeats: false) { [weak self] _ in
      self?.rotateSegment()
    }
  }

  private func rotateSegment() {
    guard movieOutput.isRecording else { return }
    rotating = true
    movieOutput.stopRecording()
  }

  func stopRecording(completion: @escaping ([String: Any]?, CaptureError?) -> Void) {
    rotateTimer?.invalidate()
    rotateTimer = nil
    rotating = false
    if !movieOutput.isRecording {
      completion(nil, .recordingFailed)
      return
    }
    stopHandler = completion
    movieOutput.stopRecording()
  }

  func listRecordings() -> [[String: Any]] {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    guard status == .authorized || status == .limited else { return [] }
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    options.fetchLimit = 200
    let result = PHAsset.fetchAssets(with: .video, options: options)
    var items: [[String: Any]] = []
    result.enumerateObjects { asset, _, _ in
      let resources = PHAssetResource.assetResources(for: asset)
      guard let video = resources.first(where: { $0.type == .video }) else { return }
      let name = video.originalFilename
      guard name.hasPrefix("USB_") else { return }
      items.append([
        "id": asset.localIdentifier,
        "name": name,
        "uri": asset.localIdentifier,
        "durationMs": Int(asset.duration * 1000),
        "shareAvailable": true,
        "deleteAvailable": true,
      ])
    }
    return items
  }

  func deleteRecording(id: String, completion: @escaping (CaptureError?) -> Void) {
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
    guard assets.count > 0 else {
      completion(.uvcFailed)
      return
    }
    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.deleteAssets(assets)
    }, completionHandler: { saved, _ in
      completion(saved ? nil : .uvcFailed)
    })
  }

  func shareRecording(id: String, from presenter: UIViewController?, completion: @escaping (CaptureError?) -> Void) {
    guard let presenter else {
      completion(.uvcFailed)
      return
    }
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
    guard let asset = assets.firstObject else {
      completion(.uvcFailed)
      return
    }
    PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { avAsset, _, _ in
      DispatchQueue.main.async {
        guard let urlAsset = avAsset as? AVURLAsset else {
          completion(.uvcFailed)
          return
        }
        let sheet = UIActivityViewController(activityItems: [urlAsset.url], applicationActivities: nil)
        if let pop = sheet.popoverPresentationController {
          pop.sourceView = presenter.view
          pop.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
        }
        presenter.present(sheet, animated: true) {
          completion(nil)
        }
      }
    }
  }

  func openRecording(id: String, from presenter: UIViewController?, completion: @escaping (CaptureError?) -> Void) {
    guard let presenter else {
      completion(.uvcFailed)
      return
    }
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
    guard let asset = assets.firstObject else {
      completion(.uvcFailed)
      return
    }
    PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { avAsset, _, _ in
      DispatchQueue.main.async {
        guard let urlAsset = avAsset as? AVURLAsset else {
          completion(.uvcFailed)
          return
        }
        let player = AVPlayer(url: urlAsset.url)
        let controller = AVPlayerViewController()
        controller.player = player
        presenter.present(controller, animated: true) {
          player.play()
          completion(nil)
        }
      }
    }
  }

  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    if output === videoOutput {
      lastFrameAt = Date()
      gotPreviewFrame = true
      frameCount += 1
      if Date().timeIntervalSince(fpsWindowStart) >= 1 {
        measuredFps = frameCount
        frameCount = 0
        fpsWindowStart = Date()
      }
      return
    }
    emitAudioPeak(sampleBuffer)
    guard !previewMuted else { return }
    renderer.enqueue(sampleBuffer)
    if synchronizer.rate == 0 {
      synchronizer.setRate(1, time: .zero)
    }
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    if let error {
      snapshotHandler?(.recordingFailed)
      snapshotHandler = nil
      emit(["type": "error", "code": "uvcFailed", "message": error.localizedDescription])
      return
    }
    guard let data = photo.fileDataRepresentation() else {
      snapshotHandler?(.uvcFailed)
      snapshotHandler = nil
      return
    }
    PHPhotoLibrary.shared().performChanges({
      let request = PHAssetCreationRequest.forAsset()
      request.addResource(with: .photo, data: data, options: nil)
    }, completionHandler: { saved, _ in
      self.snapshotHandler?(saved ? nil : .uvcFailed)
      self.snapshotHandler = nil
    })
  }

  func fileOutput(
    _ output: AVCaptureFileOutput,
    didFinishRecordingTo outputFileURL: URL,
    from connections: [AVCaptureConnection],
    error: Error?
  ) {
    let handler = stopHandler
    stopHandler = nil
    let interrupt = pendingClose || pendingDisconnect
    let wasRotating = rotating
    rotating = false
    let fileSize = (try? outputFileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    let salvageable = fileSize > 0
    if error != nil && !salvageable {
      handler?(nil, .recordingFailed)
      if !interrupt {
        emit(["type": "error", "code": "recordingFailed", "message": error?.localizedDescription ?? ""])
      }
      finishInterrupted()
      return
    }
    let completedIndex = segmentIndex
    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
    }, completionHandler: { saved, saveError in
      let payload: [String: Any] = [
        "path": outputFileURL.path,
        "hasAudio": self.hasCaptureAudio,
        "savedToMovies": false,
        "segmentIndex": completedIndex,
      ]
      if saved {
        if wasRotating && !interrupt {
          self.emit([
            "type": "recordingSaved",
            "path": outputFileURL.path,
            "hasAudio": self.hasCaptureAudio,
            "savedToMovies": false,
            "sessionContinuing": true,
            "segmentIndex": completedIndex,
          ])
          self.emit([
            "type": "segmentRolled",
            "path": outputFileURL.path,
            "segmentIndex": completedIndex,
            "elapsedMs": Int((self.sessionStartedAt.map { Date().timeIntervalSince($0) } ?? 0) * 1000),
            "sessionContinuing": true,
          ])
          self.segmentIndex = completedIndex + 1
          do {
            try self.startCurrentSegment()
            self.scheduleRotate()
          } catch {
            self.emit(["type": "error", "code": "recordingFailed", "message": error.localizedDescription])
          }
          return
        }
        if interrupt || handler == nil {
          self.emit([
            "type": "recordingSaved",
            "path": outputFileURL.path,
            "hasAudio": self.hasCaptureAudio,
            "savedToMovies": false,
            "sessionContinuing": false,
            "segmentIndex": completedIndex,
          ])
        }
        handler?(payload, nil)
        if handler == nil && !interrupt {
          self.emit(["type": "error", "code": "recordingFailed", "message": error?.localizedDescription ?? ""])
        }
        self.finishInterrupted()
      } else {
        handler?(nil, .recordingFailed)
        if !interrupt {
          self.emit(["type": "error", "code": "recordingFailed", "message": saveError?.localizedDescription ?? ""])
        }
        self.finishInterrupted()
      }
    })
  }

  private func finishInterrupted() {
    if pendingDisconnect {
      teardownSession()
      emit(["type": "disconnected", "code": "disconnected"])
    } else if pendingClose {
      teardownSession()
    }
  }

  @objc private func deviceConnected(_ notification: Notification) {
    guard let device = notification.object as? AVCaptureDevice, device.deviceType == .external else { return }
    emit([
      "type": "attached",
      "device": [
        "id": device.uniqueID,
        "name": device.localizedName,
        "hasAudio": matchingAudioDevice() != nil,
      ],
    ])
  }

  @objc private func deviceDisconnected(_ notification: Notification) {
    guard let device = notification.object as? AVCaptureDevice else { return }
    emit(["type": "detached", "deviceId": device.uniqueID])
    if device.uniqueID == openedDeviceId {
      if movieOutput.isRecording {
        pendingDisconnect = true
        movieOutput.stopRecording()
        return
      }
      teardownSession()
      emit(["type": "disconnected", "code": "disconnected"])
    }
  }

  private func videoDevices() -> [AVCaptureDevice] {
    AVCaptureDevice.DiscoverySession(
      deviceTypes: [.external],
      mediaType: .video,
      position: .unspecified
    ).devices
  }

  private func matchingAudioDevice() -> AVCaptureDevice? {
    AVCaptureDevice.DiscoverySession(
      deviceTypes: [.external],
      mediaType: .audio,
      position: .unspecified
    ).devices.first
  }

  private func preferredFormat(for device: AVCaptureDevice) -> AVCaptureDevice.Format? {
    let formats = device.formats
    let match1080 = formats.first { format in
      let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
      return dims.width == 1920 && dims.height == 1080
    }
    return match1080 ?? formats.last
  }

  private func formatMap(_ format: AVCaptureDevice.Format) -> [String: Any] {
    let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
    let fps = Int(format.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 30)
    let subtype = CMFormatDescriptionGetMediaSubType(format.formatDescription)
    return [
      "id": formatId(format),
      "width": Int(dims.width),
      "height": Int(dims.height),
      "fps": fps,
      "fourcc": fourCC(subtype),
    ]
  }

  private func formatId(_ format: AVCaptureDevice.Format) -> String {
    let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
    let fps = Int(format.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 0)
    let subtype = CMFormatDescriptionGetMediaSubType(format.formatDescription)
    return "\(dims.width)x\(dims.height)@\(fps):\(subtype)"
  }

  private func startWatchdog() {
    DispatchQueue.main.async {
      self.watchdog?.invalidate()
      self.watchdog = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
        guard let self else { return }
        let hasSignal = !self.gotPreviewFrame || Date().timeIntervalSince(self.lastFrameAt) < 2
        self.emitSignal(hasSignal: hasSignal)
      }
    }
  }

  private func stopWatchdog() {
    DispatchQueue.main.async {
      self.watchdog?.invalidate()
      self.watchdog = nil
    }
  }

  private func emitSignal(hasSignal: Bool) {
    guard let device = openedDevice else { return }
    let dims = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
    let subtype = CMFormatDescriptionGetMediaSubType(device.activeFormat.formatDescription)
    var bytes = 0
    if movieOutput.isRecording, let started = recordingStartedAt {
      let bitrate = videoBitrate()
      bytes = Int(Date().timeIntervalSince(started) * Double(bitrate) / 8)
    }
    emit([
      "type": "signal",
      "width": Int(dims.width),
      "height": Int(dims.height),
      "fps": measuredFps > 0 ? measuredFps : Int(device.activeVideoMaxFrameDuration.timescale),
      "fourcc": fourCC(subtype),
      "hasSignal": hasSignal,
      "bytesWritten": bytes,
    ])
  }

  private func fourCC(_ value: FourCharCode) -> String {
    let bytes: [UInt8] = [
      UInt8((value >> 24) & 0xff),
      UInt8((value >> 16) & 0xff),
      UInt8((value >> 8) & 0xff),
      UInt8(value & 0xff),
    ]
    return String(bytes: bytes, encoding: .ascii)?.trimmingCharacters(in: .whitespaces) ?? "\(value)"
  }

  private func emitAudioPeak(_ sampleBuffer: CMSampleBuffer) {
    if Date().timeIntervalSince(lastPeakAt) < 0.1 { return }
    lastPeakAt = Date()
    guard let block = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
    let length = CMBlockBufferGetDataLength(block)
    var data = Data(count: length)
    data.withUnsafeMutableBytes { ptr in
      if let address = ptr.baseAddress {
        CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length, destination: address)
      }
    }
    var maxValue: Int16 = 0
    data.withUnsafeBytes { raw in
      let samples = raw.bindMemory(to: Int16.self)
      for sample in samples {
        let mag = sample == Int16.min ? Int16.max : abs(sample)
        if mag > maxValue { maxValue = mag }
      }
    }
    emit(["type": "audioPeak", "peak": Double(maxValue) / 32768.0])
  }
}

private extension DateFormatter {
  static var usbStamp: DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    return formatter
  }
}
