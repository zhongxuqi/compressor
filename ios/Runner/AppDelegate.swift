import UIKit
import Flutter
import SwiftyJSON
import StoreKit
import MobileCoreServices
import ZIPFoundation
import LzmaSDK_ObjC

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let compressorQueue: DispatchQueue = DispatchQueue(label: "com.musketeer.compressor")
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
                print("pick_file")
                let req = call.arguments as! [String: String]
                self.pickFile(mimeType: req["mime_type"]!, result: result)
            case "create_archive":
                let req = call.arguments as! [String: String]
                self.compressorQueue.async {
                    let res = self.createArchive(archiveType: req["archive_type"]!, fileName: req["file_name"]!, password: req["password"]!, fileInfos: JSON(parseJSON: req["files"]!))
                    DispatchQueue.main.async {
                        result(res.rawString([.castNilToNSNull : true]))
                    }
                }
            case "get_file_headers":
                let req = call.arguments as! [String: String]
                let res = self.getFileHeaders(archiveType: req["archive_type"]!, uri: req["uri"]!, password: req["password"]!)
                result(res.rawString([.castNilToNSNull : true]))
            case "extract_file":
                let req = call.arguments as! [String: String]
                let res = self.extractFile(archiveType: req["archive_type"]!, uri: req["uri"]!, password: req["password"]!, fileName: req["file_name"]!)
                result(res.rawString([.castNilToNSNull : true]))
            case "extract_all":
                let req = call.arguments as! [String: String]
                let res = self.extractAll(archiveType: req["archive_type"]!, uri: req["uri"]!, password: req["password"]!, targetDir: req["target_dir"]!)
                result(res.rawString([.castNilToNSNull : true]))
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
    
    func createArchive(archiveType: String, fileName: String, password: String, fileInfos: JSON) -> JSON {
        switch archiveType {
        case "7z":
            return create7zArchive(fileName: fileName, password: password, fileInfos: fileInfos)
        default:
            return createZipArchive(fileName: fileName, password: password, fileInfos: fileInfos)
        }
    }
    
    func copyFileInfo(path: String, fileInfo: JSON) throws {
        let filePath = "\(path)/\(fileInfo["name"].string!)"
        if fileInfo["content_type"].string == "directory" {
            try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: false, attributes: nil)
            for fileEntry in fileInfo["files"].dictionaryValue {
                try copyFileInfo(path: filePath, fileInfo: fileEntry.value)
            }
            return
        }
        try FileManager.default.copyItem(atPath: fileInfo["uri"].string!, toPath: filePath)
    }
    
    func createZipArchive(fileName: String, password: String, fileInfos: JSON) -> JSON {
        let targetPath = NSTemporaryDirectory().appending(fileName)
        let zipPath = NSTemporaryDirectory().appending("file_dir")
        do {
            if FileManager.default.fileExists(atPath: targetPath) {
                try FileManager.default.removeItem(atPath: targetPath)
            }
            if FileManager.default.fileExists(atPath: zipPath) {
                try FileManager.default.removeItem(atPath: zipPath)
            }
            try FileManager.default.createDirectory(atPath: zipPath, withIntermediateDirectories: false, attributes: nil)
            for fileEntry in fileInfos.dictionaryValue {
                try copyFileInfo(path: zipPath, fileInfo: fileEntry.value)
            }
            
            try FileManager.default.zipItem(at: URL.init(fileURLWithPath: zipPath), to: URL.init(fileURLWithPath: targetPath), shouldKeepParent: false)
            try FileManager.default.removeItem(atPath: zipPath)
        } catch {
            print("createZipArchive error \(error.localizedDescription)")
        }
        return JSON(["archive_type": "zip", "file_name": fileName, "uri": targetPath])
    }
    
    func addFile27z(writer: LzmaSDKObjCWriter, path: String, fileInfo: JSON) {
        var filePath = ""
        if path.isEmpty {
            filePath = fileInfo["name"].string!
        } else {
            filePath = "\(path)/\(fileInfo["name"].string!)"
        }
        if fileInfo["content_type"].string == "directory" {
            for fileEntry in fileInfo["files"].dictionaryValue {
                addFile27z(writer: writer, path: filePath, fileInfo: fileEntry.value)
            }
            return
        }
        writer.addPath(fileInfo["uri"].string!, forPath: filePath)
    }
    
    func create7zArchive(fileName: String, password: String, fileInfos: JSON) -> JSON {
        let targetPath = NSTemporaryDirectory().appending(fileName)
        let writer = LzmaSDKObjCWriter(fileURL: URL.init(fileURLWithPath: targetPath))
        for fileEntry in fileInfos.dictionaryValue {
            addFile27z(writer: writer, path: "", fileInfo: fileEntry.value)
        }
        writer.method = LzmaSDKObjCMethodLZMA2
        writer.solid = true
        writer.compressionLevel = 9
        writer.encodeContent = true
        writer.encodeHeader = true
        writer.compressHeader = true
        writer.compressHeaderFull = true
        writer.writeModificationTime = false
        writer.writeCreationTime = false
        writer.writeAccessTime = false
        do {
            try writer.open()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        writer.write()
        return JSON(["archive_type": "7z", "file_name": fileName, "uri": targetPath])
    }
    
    func getFileHeaders(archiveType: String, uri: String, password: String) -> JSON {
        var res = [Any]()
        switch archiveType {
        case "7z":
            let reader = LzmaSDKObjCReader(fileURL: URL.init(fileURLWithPath: uri), andType: LzmaSDKObjCFileType7z)
            do {
                try reader.open()
                var items = [LzmaSDKObjCItem]()  // Array with selected items.
                // Iterate all archive items, track what items do you need & hold them in array.
                reader.iterate(handler: {(item: LzmaSDKObjCItem, error: Error?) -> Bool in
                    items.append(item) // If needed, store to array.
                    return true // true - continue iterate, false - stop iteration
                })
                for item in items {
                    if item.isDirectory {
                        continue
                    }
                    res.append([
                        "fileName": item.fileName ?? "",
                        "isDirectory": false,
                        "contentType": "",
                        "lastModified": item.modificationDate!.timeIntervalSince1970,
                        "fileSize": item.originalSize,
                    ])
                }
            } catch let error as NSError {
                print("Can't open archive: \(error.localizedDescription) ")
            }
        default:
            guard let archive = Archive(url: URL.init(fileURLWithPath: uri), accessMode: .read, preferredEncoding: nil) else  {
                return JSON(res)
            }
            for entry in archive {
                if entry.path.hasSuffix("/") {
                    continue
                }
                res.append([
                    "fileName": entry.path,
                    "isDirectory": false,
                    "contentType": "",
                    "lastModified": (entry.fileAttributes[.modificationDate] as! Date).timeIntervalSince1970,
                    "fileSize": entry.uncompressedSize,
                ])
            }
        }
        return JSON(res)
    }
    
    func extractFile(archiveType: String, uri: String, password: String, fileName: String) -> JSON {
        let targetPath = NSTemporaryDirectory().appending(fileName)
        switch archiveType {
        case "7z":
            let reader = LzmaSDKObjCReader(fileURL: URL.init(fileURLWithPath: uri), andType: LzmaSDKObjCFileType7z)
            do {
                try reader.open()
                var items = [LzmaSDKObjCItem]()  // Array with selected items.
                // Iterate all archive items, track what items do you need & hold them in array.
                reader.iterate(handler: {(item: LzmaSDKObjCItem, error: Error?) -> Bool in
                    if item.fileName == fileName {
                        items.append(item) // If needed, store to array.
                        return false
                    }
                    return true // true - continue iterate, false - stop iteration
                })
                if reader.extract(items, toPath: targetPath, withFullPaths: true) {
                    print("Extract failed: \(reader.lastError?.localizedDescription)")
                    return JSON(["err_code": "uncompress_error", "target_uri": targetPath])
                }
            } catch let error as NSError {
                print("Can't open archive: \(error.localizedDescription) ")
                return JSON(["err_code": "uncompress_error", "target_uri": targetPath])
            }
        default:
            do {
                guard let archive = Archive(url: URL.init(fileURLWithPath: uri), accessMode: .read, preferredEncoding: nil) else {
                    return JSON(["err_code": "uncompress_error", "target_uri": targetPath])
                }
                guard let entry = archive[fileName] else {
                    return JSON(["err_code": "uncompress_error", "target_uri": targetPath])
                }
                if FileManager.default.fileExists(atPath: targetPath) {
                    let attr = try FileManager.default.attributesOfItem(atPath: targetPath)
                    let fileSize = attr[.size] as? Int
                    if fileSize == entry.uncompressedSize {
                        return JSON(["err_code": "", "target_uri": targetPath])
                    }
                    try FileManager.default.removeItem(atPath: targetPath)
                }
                _ = try archive.extract(entry, to: URL.init(fileURLWithPath: targetPath))
            } catch {
                print("extractFile error \(error.localizedDescription)")
                return JSON(["err_code": "uncompress_error", "target_uri": targetPath])
            }
        }
        return JSON(["err_code": "", "target_uri": targetPath])
    }
    
    func extractAll(archiveType: String, uri: String, password: String, targetDir: String) -> JSON {
        switch archiveType {
        case "7z":
            let reader = LzmaSDKObjCReader(fileURL: URL.init(fileURLWithPath: uri), andType: LzmaSDKObjCFileType7z)
            do {
                try reader.open()
                var items = [LzmaSDKObjCItem]()  // Array with selected items.
                // Iterate all archive items, track what items do you need & hold them in array.
                reader.iterate(handler: {(item: LzmaSDKObjCItem, error: Error?) -> Bool in
                    items.append(item) // If needed, store to array.
                    return true // true - continue iterate, false - stop iteration
                })
                if reader.extract(items, toPath: targetDir, withFullPaths: true) {
                    print("Extract failed: \(reader.lastError?.localizedDescription)")
                    return JSON(["err_code": "uncompress_error", "target_uri": targetDir])
                }
            } catch let error as NSError {
                print("Can't open archive: \(error.localizedDescription) ")
                return JSON(["err_code": "uncompress_error", "target_uri": targetDir])
            }
        default:
            do {
                if FileManager.default.fileExists(atPath: targetDir) {
                    try FileManager.default.removeItem(atPath: targetDir)
                }
                try FileManager.default.createDirectory(at: URL.init(fileURLWithPath: targetDir), withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.unzipItem(at: URL.init(fileURLWithPath: uri), to: URL.init(fileURLWithPath: targetDir))
            } catch {
                print("extractAll error \(error.localizedDescription)")
                return JSON(["err_code": "uncompress_error", "target_uri": targetDir])
            }
        }
        return JSON(["err_code": "", "target_uri": targetDir])
    }
}

extension AppDelegate: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        print("pick_file result")
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        if let videoURL = info[.mediaURL] as? NSURL {
            let fileName = "\(TimeUtils.getMillisecondsSince1970())\((videoURL.pathExtension != nil && videoURL.pathExtension != "") ? ".\(videoURL.pathExtension!)" : "")"
            let fileURL = NSTemporaryDirectory().appending(fileName)
            do {
                try FileManager.default.copyItem(atPath: videoURL.path!, toPath: fileURL)
            } catch let error {
                print("Failed to copyItem with error: \(error.localizedDescription)")
            }
            result?(JSON([["file_name": fileName, "uri": fileURL]]).rawString([.castNilToNSNull : true]))
            controller.dismiss(animated: true)
        } else if let pickedImage = info[.originalImage] as? UIImage {
            let fileName = "\(TimeUtils.getMillisecondsSince1970()).jpg"
            let fileURL = NSTemporaryDirectory().appending(fileName)
            FileManager.default.createFile(atPath: fileURL, contents: pickedImage.jpegData(compressionQuality: 1.0), attributes: nil)
            result?(JSON([["file_name": fileName, "uri": fileURL]]).rawString([.castNilToNSNull : true]))
            controller.dismiss(animated: true)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print(urls)
        var fileInfos = JSON([JSON]())
        for urlItem in urls {
            let fileName = "\(TimeUtils.getMillisecondsSince1970())\((urlItem.pathExtension != "") ? ".\(urlItem.pathExtension)" : "")"
            let fileURL = NSTemporaryDirectory().appending(fileName)
            do {
                try FileManager.default.copyItem(atPath: urlItem.path, toPath: fileURL)
            } catch let error {
                print("Failed to copyItem with error: \(error.localizedDescription)")
            }
            fileInfos.arrayObject?.append(JSON(["file_name": fileName, "uri": fileURL]))
            usleep(1000)
        }
        result?(fileInfos.rawString([.castNilToNSNull : true]))
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
