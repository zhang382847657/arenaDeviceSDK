//
//  ImagePicker.swift
//  ArenaDeviceSDK
//  图片拍照+从相册选择图片  录像暂未实现
//  Created by 张琳 on 2017/11/6.
//  Copyright © 2017年 张琳. All rights reserved.
//

import Foundation
// 使用相机设备（AVCaptureDevice）功能时
import Photos
// 使用图片库功能
import AssetsLibrary
// 使用录制视频功能
import MobileCoreServices

//此处必须为单例模式，不然会让delegate释放掉
private let ImagePickerShareInstance = ImagePicker()

class ImagePicker : NSObject, UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    class var sharedInstance : ImagePicker {
        return ImagePickerShareInstance
    }
    
    public var data:Dictionary<String,Any>?{
        didSet
        {
            self.returnOriginal = data?["returnOriginal"] as? Bool
            if let retrunOriginal = self.returnOriginal{
                if retrunOriginal == false{
                    self.maxSize = data?["maxSize"] as? Int ?? 500
                    self.returnType = data?["returnType"] as? Int
                }
            }else{
                self.returnOriginal = false
            }
        }
    }
    private var imagePickerController:UIImagePickerController = UIImagePickerController() //图片选择视图控制器
    
    private var returnOriginal:Bool? //是否返回原图  默认不返回原图
    private var maxSize:Int = 500 //允许图片返回的最大大小(单位：kb)  默认500kb
    private var returnType:Int? //返回数据的类型  1：base64
    
    
    override init() {
        super.init()
        self.imagePickerController.delegate = self //设置代理
        self.imagePickerController.allowsEditing = false //不允许编辑图片
    }
    
    
    //弹出图片选择器
    func presentImagePicker(){
        
        //显示Sheet
        let actionSheet =  UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction.init(title: "取消", style: .cancel) { (action) in
            
        }
        let cameraAciton = UIAlertAction.init(title: "拍照", style: .default) { (action) in
            
            if  UIImagePickerController.isSourceTypeAvailable(.camera) {
                
                self.imagePickerController.sourceType = UIImagePickerControllerSourceType.camera
                self.imagePickerController.mediaTypes = [kUTTypeImage as String] //只显示拍照功能
                
                UIViewController.currentViewController()?.present(self.imagePickerController, animated: true, completion: nil)
                
            }else{
                debugPrint("不支持照相功能")
                let result = ["result": "failed","data":"不支持照相功能"]
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: self.data!["callback"] as! String), object: result, userInfo: nil)
            }
            
        }
        
        //        let videoAciton = UIAlertAction.init(title: "录像", style: .default) { (action) in
        //
        //            if  UIImagePickerController.isSourceTypeAvailable(.camera) {
        //
        //                self.imagePickerController.sourceType = UIImagePickerControllerSourceType.camera
        //                self.imagePickerController.mediaTypes = [kUTTypeMovie as String] //只显示录像功能
        //                self.imagePickerController.videoMaximumDuration = 10  //录制视频最长时间  10秒  默认为10分钟（600秒）
        //                self.imagePickerController.videoQuality = UIImagePickerControllerQualityType.typeMedium //设置视频的质量，默认就是TypeMedium
        //
        //
        //                UIViewController.currentViewController()?.present(self.imagePickerController, animated: true, completion: nil)
        //
        //
        //            }else{
        //                debugPrint("不支持录像")
        //            }
        //
        //        }
        
        let photoLibrary = UIAlertAction.init(title: "从手机相册选择", style: .default) { (action) in
            
            if  UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                
                self.imagePickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
                
                UIViewController.currentViewController()?.present(self.imagePickerController, animated: true, completion: nil)
                
            }else{
                debugPrint("不支持相册功能")
                let result = ["result": "failed","data":"不支持相册功能"]
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: self.data!["callback"] as! String), object: result, userInfo: nil)
            }
            
        }
        
        actionSheet.addAction(cancelAction)
        actionSheet.addAction(cameraAciton)
        //        actionSheet.addAction(videoAciton)
        actionSheet.addAction(photoLibrary)
        
        UIViewController.currentViewController()?.present(actionSheet, animated: true, completion: nil)
        
    }
    
    //MARK: UIImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        //获取键值UIImagePickerControllerMediaType的值，表示了当前处理的是视频还是图片
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        
        if mediaType == kUTTypeMovie as String{ //如果是视频的话
            saveMovie(info)
            picker.dismiss(animated: true, completion: nil)
        }else if mediaType == kUTTypeImage as String{ //如果是图片
            savePicture(info)
        }
        
    }
    
    
    //MARK: 保存视频方法
    func saveMovie(_ infodic:Dictionary<String,Any>){
        //系统保存到tmp目录里的视频文件的路径
        let mediaUrl: NSURL = infodic[UIImagePickerControllerMediaURL] as! NSURL
        let videoPath = mediaUrl.path
        
        //如果视频文件可以保存的话
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath!){
            //用这个方法来保存视频
            UISaveVideoAtPathToSavedPhotosAlbum(videoPath!, nil, nil, nil)
        }
    }
    
    //MARK: 保存图片方法
    func savePicture(_ infodic:Dictionary<String,Any>){
        
        //拍摄的原始图片
        let originalImage:UIImage?
        //用户修改后的图片（如果allowsEditing设置为True，那么用户可以编辑）
        let editedImage:UIImage?
        //最终要保存的图片
        let savedImage:UIImage?
        
        //从字典中获取键值UIImagePickerControllerEditedImage的值，它直接包含了图片数据
        editedImage = infodic[UIImagePickerControllerEditedImage] as? UIImage
        //从字典中获取键值UIImagePickerControllerOriginalImage的值，它直接包含了图片数据
        originalImage = infodic[UIImagePickerControllerOriginalImage] as? UIImage
        
        //判断是否有编辑图片，如果有就使用编辑的图片
        if (editedImage != nil){
            savedImage = editedImage
        }else{
            savedImage = originalImage
        }
        
        
        if self.returnOriginal! == true{ //如果返回原图
            
            guard let _ = originalImage else{
                self.imagePickerController.dismiss(animated: true, completion: {
                    let result = ["result": "failed","data":"获取原图失败"]
                    NotificationCenter.default.post(name:NSNotification.Name(rawValue: self.data!["callback"] as! String), object: result, userInfo: nil)
                })
                return
            }
            
            let filePath = self.saveImageToFile(imageData: UIImageJPEGRepresentation(originalImage!, 1.0)!)
            
            //把图片保存到相册中
            self.savedPhotosAlbum(image: originalImage!)
            
            self.imagePickerController.dismiss(animated: true, completion: {
                //把拍照结果回传过去
                let resultData:Dictionary<String,Any> = ["filePath":filePath]
                let result:Dictionary<String,Any> = ["result": "success","data":resultData]
                
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: self.data!["callback"] as! String), object: result, userInfo: nil)
            })
            
        }else{ //如果不返回原图，就根据参数去压缩图片质量
            
            
            //得到压缩尺寸后的图片
            let resizeImage:UIImage? = self.resizeImage(originalImg: savedImage!)
            //得到压缩画质后的图片二进制流
            if let resizeImage = resizeImage{
                
                self.compressImageSize(image: resizeImage, imageData: { (data, base64) in
                    
                    let imageData:Data? = data
                    
                    if let imageData = imageData{
                        
                        //图片在磁盘上的路径
                        let filePath = self.saveImageToFile(imageData: imageData)
                        var resultData:Dictionary<String,Any> = ["filePath":filePath]
                        
                        if let base64 = base64{ //如果需要返回base64
                            resultData["base64"] = base64
                        }
                        
                        //保存图片到相册
                        self.savedPhotosAlbum(image: UIImage(data: imageData)!)
                        
                        //把结果回传，并关闭当前ImagePicker
                        DispatchQueue.main.async(execute: {
                            
                            self.imagePickerController.dismiss(animated: true, completion: {
                                let result:Dictionary<String,Any> = ["result": "success","data":resultData]
                                NotificationCenter.default.post(name:NSNotification.Name(rawValue: self.data!["callback"] as! String), object: result, userInfo: nil)
                            })
                        })
                        
                    }else{
                        
                        DispatchQueue.main.async(execute: {
                            
                            self.imagePickerController.dismiss(animated: true, completion: {
                                let result = ["result": "failed","data":"图片二进制流获取失败"]
                                NotificationCenter.default.post(name:NSNotification.Name(rawValue: self.data!["callback"] as! String), object: result, userInfo: nil)
                            })
                            
                        })
                    }
                    
                })
                
                
            }else{
                self.imagePickerController.dismiss(animated: true, completion: {
                    let result = ["result": "failed","data":"图片画质压缩失败"]
                    NotificationCenter.default.post(name:NSNotification.Name(rawValue: self.data!["callback"] as! String), object: result, userInfo: nil)
                })
                
            }
            
        }
        
    }
    
    
    //MARK: 保存图片到相册
    func savedPhotosAlbum(image:UIImage){
        //如果当前是拍照的话，才把图片保存到相册，否则不保存
        if self.imagePickerController.sourceType == .camera{
            //判断是否支持把图片保存到相册中
            if  UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                //保存图片到用户的相机胶卷中
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }else{
                debugPrint("不支持把图片保存到相册中")
            }
        }
    }
    
    //MARK: 图片尺寸压缩
    /**
     1、图片宽或者高均小于或等于1280时图片尺寸保持不变，不改变图片大小
     2、宽或者高大于1280，但是图片宽度高度比小于或等于2，则将图片宽或者高取值大的等比压缩至1280
     3、宽或者高均大于1280，但是图片宽高比大于2，则宽或者高取值小的等比压缩至1280
     4、宽或者高，只有一个值大于1280，并且宽高比超过2，不改变图片大小
     */
    func resizeImage(originalImg:UIImage) -> UIImage?{
        
        //prepare constants
        let width = originalImg.size.width
        let height = originalImg.size.height
        
        debugPrint("原图尺寸：w = \(width) h = \(height)")
        
        let scale = width/height
        
        var sizeChange = CGSize()
        
        if width <= 1280 && height <= 1280{ //a，图片宽或者高均小于或等于1280时图片尺寸保持不变，不改变图片大小
            return originalImg
        }else if width > 1280 || height > 1280 {//b,宽或者高大于1280，但是图片宽度高度比小于或等于2，则将图片宽或者高取大的等比压缩至1280
            
            if scale <= 2 && scale >= 1 {
                let changedWidth:CGFloat = 1280
                let changedheight:CGFloat = changedWidth / scale
                sizeChange = CGSize(width: changedWidth, height: changedheight)
                
            }else if scale >= 0.5 && scale <= 1 {
                
                let changedheight:CGFloat = 1280
                let changedWidth:CGFloat = changedheight * scale
                sizeChange = CGSize(width: changedWidth, height: changedheight)
                
            }else if width > 1280 && height > 1280 {//宽以及高均大于1280，但是图片宽高比大于2时，则宽或者高取小的等比压缩至1280
                
                if scale > 2 {//高的值比较小
                    
                    let changedheight:CGFloat = 1280
                    let changedWidth:CGFloat = changedheight * scale
                    sizeChange = CGSize(width: changedWidth, height: changedheight)
                    
                }else if scale < 0.5{//宽的值比较小
                    
                    let changedWidth:CGFloat = 1280
                    let changedheight:CGFloat = changedWidth / scale
                    sizeChange = CGSize(width: changedWidth, height: changedheight)
                    
                }
            }else {//d, 宽或者高，只有一个大于1280，并且宽高比超过2，不改变图片大小
                return originalImg
            }
        }
        
        UIGraphicsBeginImageContext(sizeChange)
        
        //draw resized image on Context
        originalImg.draw(in: CGRect(x: 0, y: 0, width: sizeChange.width, height: sizeChange.height))
        //create UIImage
        let resizedImg = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        debugPrint("压缩后尺寸:w= \(String(describing: resizedImg?.size.width)) h = \(String(describing: resizedImg?.size.height))")
        
        return resizedImg
        
    }
    
    
    //MARK: 图片画质压缩
    //1000kb以下的图片控制在100kb-200kb之间
    func compressImageSize(image:UIImage, imageData:@escaping ((_ data:Data?, _ base64:String?)->Void)){
        
        //开启子线程去处理图片画质压缩
        DispatchQueue.global().async {
            
            var zipImageData:Data? = UIImageJPEGRepresentation(image, 1.0)
            
            guard let _  = zipImageData else{
                imageData(nil, nil)
                return
            }
            
            //图片大小
            var originalImgSize:Int = zipImageData!.count / 1024
            debugPrint("图片压缩前:\(originalImgSize) kb")
            
            //进行循环压缩，直到逼近指定大小
            var compress:CGFloat = 1.0
            while originalImgSize > self.maxSize && compress > 0.01{
                compress -= 0.02
                zipImageData = UIImageJPEGRepresentation(image, compress)
                originalImgSize = zipImageData!.count / 1024
            }
            
            debugPrint("图片压缩后:\(originalImgSize) kb")
            
            if let returnType = self.returnType, returnType == 1{ //如果需要返回base64
                //图片base64
                let base64 = zipImageData!.base64EncodedString(options: .endLineWithLineFeed)
                imageData(zipImageData, base64)
                
            }else{
                imageData(zipImageData!, nil)
            }
            
        }
        
    }
    
    
    //MARK: 保存图片到磁盘中
    func saveImageToFile(imageData:Data) -> String{
        
        //在沙盒Tmp目录下创建ArenaPhotoFile文件夹
        let myDire: String = NSTemporaryDirectory() + "ArenaPhotoFile"
        try! FileManager.default.createDirectory(atPath: myDire, withIntermediateDirectories: true, attributes: nil)
        
        
        //把图片保存本地沙盒中
        let timeInterval:TimeInterval = NSDate().timeIntervalSince1970 //获取当前时间戳
        let imagePath = NSTemporaryDirectory() + "ArenaPhotoFile/\( Int(timeInterval)).jpg" //图片路径
        FileManager.default.createFile(atPath: imagePath, contents: imageData, attributes: nil)
        
        return imagePath
        
    }
    
    
    
}

