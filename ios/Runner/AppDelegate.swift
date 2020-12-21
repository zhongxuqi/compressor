import UIKit
import Flutter
import HandyJSON
import StoreKit
import MobileCoreServices

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var imagePicker = UIImagePickerController()
    private var result: FlutterResult?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FileManager.default.clearTmpDirectory()
        imagePicker.delegate = self
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let compressorChannel = FlutterMethodChannel(name: "com.musketeer.compressor", binaryMessenger: controller.binaryMessenger)
        compressorChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "feedback":
                SKStoreReviewController.requestReview()
            case "pick_file":
                let req = call.arguments as! [String: String]
                self.pickFile(mimeType: req["mime_type"]!, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func pickFile(mimeType: String, result: @escaping FlutterResult) {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        if mimeType.starts(with: "image") {
            self.result = result
            imagePicker.sourceType = .photoLibrary
            
            imagePicker.mediaTypes = [kUTTypeImage as String]
            controller.present(imagePicker, animated: true)
        } else if mimeType.starts(with: "video") {
            self.result = result
            imagePicker.sourceType = .photoLibrary
            imagePicker.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String, kUTTypeMPEG4 as String, kUTTypeAVIMovie as String]
            controller.present(imagePicker, animated: true)
        } else {
            self.result = result
            let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeText),String(kUTTypeContent),String(kUTTypeItem),String(kUTTypeData)], in: .import)
            documentPicker.delegate = self
            controller.present(documentPicker, animated: true)
        }
    }
}

extension AppDelegate: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        if let videoURL = info[.mediaURL] as? NSURL {
            let fileName = "\(TimeUtils.getMillisecondsSince1970())\((videoURL.pathExtension != nil && videoURL.pathExtension != "") ? ".\(videoURL.pathExtension!)" : "")"
            let fileURL = NSTemporaryDirectory().appending(fileName)
            do {
                try FileManager.default.copyItem(atPath: videoURL.path!, toPath: fileURL)
            } catch let error {
                print("Failed to copyItem with error: \(error.localizedDescription)")
            }
            let fileInfo = FileInfo()
            fileInfo.fileName = fileName
            fileInfo.uri = fileURL
            result?([fileInfo].toJSONString())
            controller.dismiss(animated: true)
        } else if let pickedImage = info[.originalImage] as? UIImage {
            let fileName = "\(TimeUtils.getMillisecondsSince1970()).jpg"
            let fileURL = NSTemporaryDirectory().appending(fileName)
            FileManager.default.createFile(atPath: fileURL, contents: pickedImage.jpegData(compressionQuality: 1.0), attributes: nil)
            let fileInfo = FileInfo()
            fileInfo.fileName = fileName
            fileInfo.uri = fileURL
            result?([fileInfo].toJSONString())
            controller.dismiss(animated: true)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print(urls)
        var fileInfos = [FileInfo]()
        for urlItem in urls {
            let fileName = "\(TimeUtils.getMillisecondsSince1970())\((urlItem.pathExtension != "") ? ".\(urlItem.pathExtension)" : "")"
            let fileURL = NSTemporaryDirectory().appending(fileName)
            do {
                try FileManager.default.copyItem(atPath: urlItem.path, toPath: fileURL)
            } catch let error {
                print("Failed to copyItem with error: \(error.localizedDescription)")
            }
            let fileInfo = FileInfo()
            fileInfo.fileName = fileName
            fileInfo.uri = fileURL
            fileInfos.append(fileInfo)
            usleep(1000)
        }
        result?(fileInfos.toJSONString())
        controller.dismiss(animated: true)
    }
}

extension FileManager {
    func clearTmpDirectory() {
        do {
            let tmpDirectory = try contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach {[unowned self] file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try self.removeItem(atPath: path)
            }
        } catch {
            print(error)
        }
    }
}
