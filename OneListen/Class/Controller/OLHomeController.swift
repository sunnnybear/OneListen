//
//  OLHomeController.swift
//  OneListen
//
//  Created by HanYunpeng on 2018/8/9.
//  Copyright © 2018年 HanYunpeng. All rights reserved.
//

import UIKit
import AVFoundation

class OLHomeController: UIViewController {
    //audioRecorder和audioPlayer，一个用于录音，一个用于播放
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    //获取音频会话单例
    let audioSession = AVAudioSession.sharedInstance()
    var isAllowed:Bool = false
    
    //定义音频的编码参数
    let recordSettings = [
        AVSampleRateKey : NSNumber(value: Float(44100.0)),//声音采样率
        AVFormatIDKey : NSNumber(value: Int32(kAudioFormatMPEG4AAC)),//编码格式
        AVNumberOfChannelsKey : NSNumber(value: 1),//采集音轨
        AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue))]//音频质量
    var startCount = 0
    var endCount = 0
    
    var timer = Timer()
    var isPlaying = false
    
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var outputPortButton: UIButton!
    
    @IBOutlet weak var startTimeLabel: UILabel!
    
    @IBOutlet weak var endTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            //初始化实例
            try audioRecorder = AVAudioRecorder(url: self.directoryURL()! as URL,settings: recordSettings)
            audioRecorder.delegate = self
            //准备录音
            audioRecorder.prepareToRecord()
            try! audioSession.overrideOutputAudioPort(.speaker)
        }  catch let error as NSError{
            print(error)
        }

        
    }
    
    func directoryURL() -> NSURL? {
        //定义并构建一个url来保存音频，音频文件名为ddMMyyyyHHmmss.caf，根据时间来设置存储文件名
        let currentDateTime = NSDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyyHHmmss"
        //以下2种格式都可以
        //let recordingName = formatter.stringFromDate(currentDateTime)+".caf"
        let recordingName = formatter.string(from: currentDateTime as Date)+".m4a"
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as NSURL
        let soundURL = documentDirectory.appendingPathComponent(recordingName)
        return soundURL! as NSURL
    }

    
    @IBAction func recordingTap(_ sender: Any) {
        recordButton.isSelected = !recordButton.isSelected
        
        if recordButton.isSelected {
            //如果正在播放，先停止播放
            if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
                audioPlayer.stop()
            }
            //是否正在录音，如果没有，开始录音
            if !audioRecorder.isRecording {
                do {
                    try audioSession.setActive(true)
                    audioRecorder.record()
                    endCount = 0
                    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
                }catch let error as NSError{
                    print(error)
                }
            }
           
        }
        else{
            if audioRecorder.isRecording{
                audioRecorder.stop()
                do {
                    try audioSession.setActive(false)
                    timer.invalidate()
                } catch let error as NSError{
                    print(error)
                }
            }

        }
      
        
    }
    
    @IBAction func outputPortButtonTap(_ sender: Any) {
        outputPortButton.isSelected = !outputPortButton.isSelected
        if outputPortButton.isSelected {
            try! audioSession.overrideOutputAudioPort(.speaker)
        }
        else{
            try! audioSession.overrideOutputAudioPort(.none)
        }
    }
    @IBAction func playingTap(_ sender: Any) {
        playButton.isSelected = !playButton.isSelected
        if playButton.isSelected {
            if (!audioRecorder.isRecording){
                do {
                    //创建音频播放器AVAudioPlayer，用于在录音完成之后播放录音
                    let url:NSURL? = audioRecorder.url as NSURL
                    if let url = url{
                        try audioPlayer = AVAudioPlayer(contentsOf: url as URL)
                        audioPlayer.delegate = self
                        
                        audioPlayer.play()
                        
                        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateStartTimer), userInfo: nil, repeats: true)
                    }
                } catch let error as NSError{
                    print(error)
                }
            }
            else{
                audioRecorder.stop()
                timer.invalidate()
                recordButton.isSelected = false
                do {
                    //创建音频播放器AVAudioPlayer，用于在录音完成之后播放录音
                    let url:NSURL? = audioRecorder.url as NSURL
                    if let url = url{
                        try audioPlayer = AVAudioPlayer(contentsOf: url as URL)
                        audioPlayer.delegate = self
                        
                        audioPlayer.play()
                        
                        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateStartTimer), userInfo: nil, repeats: true)
                    }
                } catch let error as NSError{
                    print(error)
                }
            }
        }
        else{
            audioRecorder.pause()
            timer.invalidate()
        }
        
    }
    
    @objc func updateTimer(){
        endCount += 1;
        let min = endCount / 60
        let sec = endCount % 60
        self.endTimeLabel.text = NSString(format: "%02d:%02d", min,sec) as String
        
    }
    
    @objc func updateStartTimer(){
        startCount += 1;
        if startCount >= endCount {
            timer.invalidate()
            startCount = 0
        }
        let min = startCount / 60
        let sec = startCount % 60
        self.startTimeLabel.text = NSString(format: "%02d:%02d", min,sec) as String
        
    }
}




extension OLHomeController:AVAudioRecorderDelegate{
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag{
            
        }
    }
}

extension OLHomeController:AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag{
            print("播放完成!")
            self.playButton.isSelected = false
        }
    }
}
