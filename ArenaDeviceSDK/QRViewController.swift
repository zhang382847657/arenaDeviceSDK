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
    
    private var session: AVCaptureSession!  //输入输出的中间桥梁
    
    private var myInput: AVCaptureDeviceInput!  //创建输入流
    private var myOutput: AVCaptureMetadataOutput!  //创建输出流
    
    private var bgView = UIView()
    private var barcodeView = UIView()
    
    private var timer = Timer() //计时器
    private var scanLine = UIImageView()
    
    private var closeBtn = UIButton(type: .custom) //右上角关闭按钮
    
    private let bundle = Bundle.init(url: Bundle.init(for: QRViewController.self).url(forResource: "images", withExtension: "bundle")!) //bundle
    
    private var data:Dictionary<String,Any>!
    private var canUse:Bool = true //用来判断能否使用扫一扫功能
    private var isSimulator:Bool = false //是否是模拟器
    
    
    //初始化页面
    // -Params data 用来拿到callbackID的
    init(data:Dictionary<String,Any>) {
        super.init(nibName: nil, bundle: nil)
        self.data = data
        
        #if arch(i386) || arch(x86_64)  //判断是否是虚拟机
            self.isSimulator = true
            debugPrint("请用真机来调试该功能")
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.isSimulator == false { //如果不是在虚拟机上运行
            
            //获取相机权限
            let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            if (authStatus != .restricted && authStatus != .denied) == false { //如果用户没有授权访问相机的权限
                self.canUse = false
                return
            }
            
            //设置定时器，延迟2秒启动
            self.timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(moveScannerLayer(_:)), userInfo: nil, repeats: true)
            
            //初始化链接对象
            self.session = AVCaptureSession.init()
            //设置高质量采集率
            self.session.canSetSessionPreset(AVCaptureSessionPresetHigh)
            
            //获取摄像设备
            let device: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            
            //捕捉异常，并处理
            do {
                self.myInput = try AVCaptureDeviceInput.init(device: device)
                self.myOutput = AVCaptureMetadataOutput.init()
                self.session.addInput(self.myInput)
                self.session.addOutput(self.myOutput)
            } catch {
                debugPrint("error")
            }
            
            //创建预览视图
            self.createBackGroundView()
            
            //设置扫描范围(横屏)
            self.myOutput.rectOfInterest = CGRect(x: 0.35, y: 0.2, width: UIScreen.main.bounds.width * 0.6 / UIScreen.main.bounds.height, height: 0.6)
            
            //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
            self.myOutput.metadataObjectTypes = [
                AVMetadataObjectTypeQRCode,
                AVMetadataObjectTypeCode39Code,
                AVMetadataObjectTypeCode128Code,
                AVMetadataObjectTypeCode39Mod43Code,
                AVMetadataObjectTypeEAN13Code,
                AVMetadataObjectTypeEAN8Code,
                AVMetadataObjectTypeCode93Code]
            
            //创建串行队列
            let dispatchQueue = DispatchQueue(label: "queue", attributes: [])
            //设置输出流的代理
            self.myOutput!.setMetadataObjectsDelegate(self, queue: dispatchQueue)
            
            //创建预览图层
            let myLayer = AVCaptureVideoPreviewLayer.init(session: self.session)
            myLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill  //设置预览图层的填充方式
            myLayer?.frame = self.view.layer.bounds  //设置预览图层的frame
            self.bgView.layer.insertSublayer(myLayer!, at: 0)  //将预览图层(摄像头画面)插入到预览视图的最底部
            
            //开始扫描
            self.session.startRunning()
            
            //        self.timer.fire()
            
        }else{
            self.view.backgroundColor = UIColor.white
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if self.canUse == false{
            //弹出提示框
            let alert = UIAlertController(title: nil, message: "请在设置中打开相机权限", preferredStyle: .alert)
            
            let tempAction = UIAlertAction(title: "确定", style: .cancel) { (action) in
                
                self.dismiss(animated: true, completion: {
                   
                    let result = ["result": "failed","data":"设备没有开放相机的权限"]
                    NotificationCenter.default.post(name:NSNotification.Name(rawValue: self.data["callback"] as! String), object: result, userInfo: nil)
                })
                return
            }
            alert.addAction(tempAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        if self.isSimulator == true {
            
            self.dismiss(animated: true, completion: {
             
                let result = ["result": "failed","data":"模拟器不支持扫描功能，请使用真机来调试"]
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: self.data["callback"] as! String), object: result, userInfo: nil)
            })
            return
        }
        
    }
    
    //扫描结果，代理
    func captureOutput(_ output: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        if metadataObjects.count > 0 {
            
            //停止扫描
            self.session.stopRunning()
            //计时器销毁
            self.timer.invalidate()
            
            let object = metadataObjects[0]
            let string: String = (object as AnyObject).stringValue //扫描的结果
            debugPrint("扫描结果 == \(string)")
            
            self.dismiss(animated: true, completion: {
                //把扫描的结果回传过去
                let result = ["result": "success","data":string]
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: self.data["callback"] as! String), object: result, userInfo: nil)
            })
        }
        
    }
    
    
    //创建预览视图
    func createBackGroundView() {
        
        self.bgView.frame = UIScreen.main.bounds
        self.bgView.backgroundColor = UIColor.black
        self.view.addSubview(self.bgView)
        
        //右上角关闭按钮
        self.closeBtn.frame = CGRect(x: UIScreen.main.bounds.width - 44 - 20, y: 25, width: 44, height: 44)
        self.closeBtn.setImage(UIImage(named: "close", in: bundle, compatibleWith: nil), for: .normal)
        self.closeBtn.addTarget(self, action: #selector(closeCurrentViewController), for: .touchUpInside)
        self.view.addSubview(self.closeBtn)
        
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
        scanLine.image = UIImage(named: "icon_line", in: bundle, compatibleWith: nil)
        barcodeView.addSubview(scanLine)
    }
    
    //扫描线滚动
    @objc func moveScannerLayer(_ timer : Timer) {
        
        self.scanLine.frame = CGRect(x: 0, y: 0, width: self.barcodeView.frame.size.width, height: self.scanLine.frame.size.height)
        
        UIView.animate(withDuration: 1.5) {
            self.scanLine.frame = CGRect(x: self.scanLine.frame.origin.x, y: self.barcodeView.frame.size.height - 5, width: self.scanLine.frame.size.width, height: self.scanLine.frame.size.height)
        }
    }
    
    //关闭当前页
    @objc func closeCurrentViewController(sender:UIButton){
        
        self.dismiss(animated: true) {
            //停止扫描
            self.session.stopRunning()
            //计时器销毁
            self.timer.invalidate()
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

