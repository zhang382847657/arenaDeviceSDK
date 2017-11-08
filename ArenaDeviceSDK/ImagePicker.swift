//
//  ImagePicker.swift
//  ArenaDeviceSDK
//
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
    
    public var data:Dictionary<String,Any>!
    private var imagePickerController:UIImagePickerController = UIImagePickerController()
    
    
    override init() {
        super.init()
        self.imagePickerController.delegate = self //设置代理
        self.imagePickerController.allowsEditing = true //允许编辑图片
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
                debugPrint("不支持照相")
            }
            
        }
        
        let videoAciton = UIAlertAction.init(title: "录像", style: .default) { (action) in
            
            if  UIImagePickerController.isSourceTypeAvailable(.camera) {
                
                self.imagePickerController.sourceType = UIImagePickerControllerSourceType.camera
                self.imagePickerController.mediaTypes = [kUTTypeMovie as String] //只显示录像功能
                self.imagePickerController.videoMaximumDuration = 10  //录制视频最长时间  10秒  默认为10分钟（600秒）
                self.imagePickerController.videoQuality = UIImagePickerControllerQualityType.typeMedium //设置视频的质量，默认就是TypeMedium
                
                
                UIViewController.currentViewController()?.present(self.imagePickerController, animated: true, completion: nil)
                
                
            }else{
                debugPrint("不支持录像")
            }
            
        }
        
        let photoLibrary = UIAlertAction.init(title: "从手机相册选择", style: .default) { (action) in
            
            if  UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                
                self.imagePickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
                self.imagePickerController.mediaTypes = UIImagePickerController.availableMediaTypes(for: UIImagePickerControllerSourceType.camera)! //视频+图片
                
                UIViewController.currentViewController()?.present(self.imagePickerController, animated: true, completion: nil)
                
            }else{
                debugPrint("不支持相册")
            }
        
        }
        
        actionSheet.addAction(cancelAction)
        actionSheet.addAction(cameraAciton)
        actionSheet.addAction(videoAciton)
        actionSheet.addAction(photoLibrary)
        
        UIViewController.currentViewController()?.present(actionSheet, animated: true, completion: nil)
        
    }

    //MARK: UIImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        //获取键值UIImagePickerControllerMediaType的值，表示了当前处理的是视频还是图片
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        
        if mediaType == kUTTypeMovie as String{ //如果是视频的话
            saveMovie(info)
        }else if mediaType == kUTTypeImage as String{ //如果是图片
            savePicture(info)
        }
        
        picker.dismiss(animated: true, completion: nil)

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
        
        //保存图片到用户的相机胶卷中
        UIImageWriteToSavedPhotosAlbum(savedImage!, nil, nil, nil)
        

        //得到压缩尺寸后的图片
        let resizeImage:UIImage? = self.resizeImage(originalImg: savedImage!)
        //得到压缩画质后的图片二进制流
        if let resizeImage = resizeImage{
            let imageData:Data? = self.compressImageSize(image: resizeImage)
            
            if let imageData = imageData{
                
                //把图片保存到tmp目录下的PhotoFile文件夹下
                let timeInterval:TimeInterval = NSDate().timeIntervalSince1970 //获取当前时间戳
                let imagePath = NSTemporaryDirectory() + "PhotoFile/\( Int(timeInterval)).jpg" //图片路径
                debugPrint("图片路径:\(imagePath)")
                FileManager.default.createFile(atPath: imagePath, contents: imageData, attributes: nil)
                
                //图片base64
                let base64:String? = imageData.base64EncodedString(options: .endLineWithLineFeed)
                if let base64 = base64{
                    debugPrint("图片base64: \(base64)")
                }else{
                    debugPrint("图片转base64失败")
                }
            }else{
                debugPrint("图片二进制流获取失败")
            }

        }else{
            debugPrint("图片尺寸压缩失败")
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
        
        debugPrint("压缩后尺寸：w = \(resizedImg?.size.width) h = \(resizedImg?.size.height)")
        
        return resizedImg
        
    }
    
    
    //MARK: 图片画质压缩
    //1000kb以下的图片控制在100kb-200kb之间
    func compressImageSize(image:UIImage) -> Data?{
        
        //图片的二进制流
        var zipImageData:Data? = UIImageJPEGRepresentation(image, 1.0)
        //图片大小
        let originalImgSize:Int = zipImageData!.count / 1024
        
        debugPrint("图片原始画质大小: \(originalImgSize)")
        
        if originalImgSize > 1500 {
            zipImageData = UIImageJPEGRepresentation(image,0.1)!
        }else if originalImgSize > 600 {
            zipImageData = UIImageJPEGRepresentation(image,0.2)!
        }else if originalImgSize > 400 {
            zipImageData = UIImageJPEGRepresentation(image,0.3)!
        }else if originalImgSize > 300 {
            zipImageData = UIImageJPEGRepresentation(image,0.4)!
        }else if originalImgSize > 200 {
            zipImageData = UIImageJPEGRepresentation(image,0.5)!
        }
        
        debugPrint("图片压缩后画质大小: \(zipImageData!.count / 1024)")
        
        return zipImageData
    }
    


        
    
}

