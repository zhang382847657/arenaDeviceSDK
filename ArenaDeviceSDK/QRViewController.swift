//
//  QRViewController.swift
//  ArenaDeviceSDK
//  扫二维码/条形码
//  Created by 张琳 on 2017/10/24.
//  Copyright © 2017年 张琳. All rights reserved.
//

import UIKit
import AVFoundation

class QRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var session: AVCaptureSession!  //输入输出的中间桥梁
    
    var myInput: AVCaptureDeviceInput!  //创建输入流
    var myOutput: AVCaptureMetadataOutput!  //创建输出流
    
    var bgView = UIView()
    var barcodeView = UIView()
    
    var timer = Timer()
    var scanLine = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //设置定时器，延迟2秒启动
        self.timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(moveScannerLayer(_:)), userInfo: nil, repeats: true)
        
        //初始化链接对象
        self.session = AVCaptureSession.init()
        //设置高质量采集率
        self.session.canSetSessionPreset(AVCaptureSession.Preset.high)
        
        //获取摄像设备
        
        let device: AVCaptureDevice = AVCaptureDevice.default(for: .video)!
        
        //捕捉异常，并处理
        do {
            self.myInput = try AVCaptureDeviceInput.init(device: device)
            self.myOutput = AVCaptureMetadataOutput.init()
            self.session.addInput(self.myInput)
            self.session.addOutput(self.myOutput)
        } catch {
            print("error")
        }
        
        //创建预览视图
        self.createBackGroundView()
        
        //设置扫描范围(横屏)
        self.myOutput.rectOfInterest = CGRect(x: 0.35, y: 0.2, width: UIScreen.main.bounds.width * 0.6 / UIScreen.main.bounds.height, height: 0.6)
        
        //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
        myOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.ean13,  AVMetadataObject.ObjectType.ean8, AVMetadataObject.ObjectType.code128]
        
        //创建串行队列
        let dispatchQueue = DispatchQueue(label: "queue", attributes: [])
        //设置输出流的代理
        self.myOutput.setMetadataObjectsDelegate(self, queue: dispatchQueue)
        
        //创建预览图层
        let myLayer = AVCaptureVideoPreviewLayer.init(session: self.session)
        myLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill  //设置预览图层的填充方式
        myLayer.frame = self.view.layer.bounds  //设置预览图层的frame
        self.bgView.layer.insertSublayer(myLayer, at: 0)  //将预览图层(摄像头画面)插入到预览视图的最底部
        
        //开始扫描
        self.session.startRunning()
//        self.timer.fire()
    }
    
    
    //扫描结果，代理
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection){
        
        if metadataObjects.count > 0 {
            
            //停止扫描
            self.session.stopRunning()
            //计时器暂停
            self.timer.fireDate = Date.distantFuture
            //计时器销毁
           // self.timer.invalidate()
            
            let object = metadataObjects[0]
            let string: String = (object as AnyObject).stringValue
            if let url = URL(string: string) {
                if UIApplication.shared.canOpenURL(url) {
                    self.navigationController?.popViewController(animated: true)
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                    //去打开地址链接
                } else {
                    //获取非链接结果
                    let alertViewController = UIAlertController(title: "扫描结果", message: (object as AnyObject).stringValue, preferredStyle: .alert)
                    let actionCancel = UIAlertAction(title: "退出", style: .cancel, handler: { (action) in
                        _ = self.navigationController?.popViewController(animated: true)
                    })
                    let actinSure = UIAlertAction(title: "再次扫描", style: .default, handler: { (action) in
                        self.session.startRunning()
                        self.timer.fire()
                    })
                    alertViewController.addAction(actionCancel)
                    alertViewController.addAction(actinSure)
                    self.present(alertViewController, animated: true, completion: nil)
                }
            }
        }
    
    }
    
    //创建预览视图
    func createBackGroundView() {
        
        self.bgView.frame = UIScreen.main.bounds
        self.bgView.backgroundColor = UIColor.black
        self.view.addSubview(self.bgView)
        
        //灰色蒙版
        let topView = UIView(frame: CGRect(x: 0, y: 0,  width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * 0.35))
        
        let leftView = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height * 0.35, width: UIScreen.main.bounds.size.width * 0.2, height: UIScreen.main.bounds.size.width * 0.6))
        
        let rightView = UIView(frame: CGRect(x: UIScreen.main.bounds.size.width * 0.8, y: UIScreen.main.bounds.size.height * 0.35, width: UIScreen.main.bounds.size.width * 0.2, height: UIScreen.main.bounds.size.width * 0.6))
        
        let bottomView = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.width * 0.6 + UIScreen.main.bounds.size.height * 0.35, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * 0.65 - UIScreen.main.bounds.size.width * 0.6))
        
        topView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        bottomView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        leftView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        rightView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        
        //文字说明
        let label = UILabel(frame: CGRect(x: 0, y: 10, width: UIScreen.main.bounds.size.width, height: 21))
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.white
        label.text = "将二维码/条形码放入扫描框内，即自动扫描"
        bottomView.addSubview(label)
        
        self.bgView.addSubview(topView)
        self.bgView.addSubview(bottomView)
        self.bgView.addSubview(leftView)
        self.bgView.addSubview(rightView)
        
        
        //屏幕中间扫描区域视图（透明）
        barcodeView.frame = CGRect(x: UIScreen.main.bounds.size.width * 0.2, y: UIScreen.main.bounds.size.height * 0.35, width: UIScreen.main.bounds.size.width * 0.6, height: UIScreen.main.bounds.size.width * 0.6)
        barcodeView.backgroundColor = UIColor.clear
        barcodeView.layer.borderWidth = 1.0
        barcodeView.layer.borderColor = UIColor.white.cgColor
        self.bgView.addSubview(barcodeView)
        
        //扫描线
        scanLine.frame = CGRect(x: 0, y: 0, width: barcodeView.frame.size.width, height: 5)
//        scanLine.backgroundColor = UIColor.green
        scanLine.image = UIImage(named: "ArenaDeviceSDK.framework/images.bundle/icon_line")
        barcodeView.addSubview(scanLine)
    }
    
    //扫描线滚动
    @objc func moveScannerLayer(_ timer : Timer) {
        
        self.scanLine.frame = CGRect(x: 0, y: 0, width: self.barcodeView.frame.size.width, height: self.scanLine.frame.size.height)
        
        UIView.animate(withDuration: 1.5) {
            self.scanLine.frame = CGRect(x: self.scanLine.frame.origin.x, y: self.barcodeView.frame.size.height - 5, width: self.scanLine.frame.size.width, height: self.scanLine.frame.size.height)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        self.timer.invalidate() //计时器停止
    }
    
}
