//
//  VideoDetailViewController.swift
//  MyTvApp
//
//  Created by kevin hijlkema on 08/01/2020.
//  Copyright © 2020 KhiProjects. All rights reserved.
//

import UIKit

import AVKit

class VideoDetailViewController: UIViewController {

    //MARK: - Members
    var imaPlayerVC: IMAVideoPlayerViewController? = nil
    var adsHasBeenPlayed = false
    //
    var avPlayer: AVPlayer?=nil
    var avPlayerVC: AVPlayerViewController?=nil
    //MARK: - View Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loadPlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if adsHasBeenPlayed {
            loadVideo()
        } else {
            requestAds()
        }
    }
    
    //MARK: - Life Cycle
    deinit {
        NSLog("Deinit VideoDetailViewController ***")

        avPlayerVC?.view.removeFromSuperview()
        avPlayerVC?.removeFromParent()
        
        avPlayerVC = nil
        avPlayer = nil
        // IMA PARTS
        imaPlayerVC = nil
    }
    
    
    //MARK: - API
    func configure(withAds ads: Bool) {
        self.adsHasBeenPlayed = !ads
    }
    
    //MARK: - Methodes
    func loadPlayer() {
        guard avPlayer == nil,
            avPlayerVC == nil else {return}
        
        let player = AVPlayer(playerItem: nil)
        
        let vc = AVPlayerViewController(nibName: nil, bundle: nil)
        vc.player = player
        vc.view.frame = self.view.bounds
        
        self.view.addSubview(vc.view)
        self.addChild(vc)
        vc.didMove(toParent: self)
        
        
        // Store Ref
        self.avPlayer = player
        self.avPlayerVC = vc
    }

    func loadVideo() {
        let videoURLString =
        "https://wolverine.raywenderlich.com/content/ios/tutorials/video_streaming/foxVillage.m3u8"
        guard let url = URL(string: videoURLString) else {return}
        let item = AVPlayerItem(url: url)
        self.avPlayer!.replaceCurrentItem(with: item)
        self.avPlayer!.play()
    }
    
    
    func playContentIfReady() {
        guard adsHasBeenPlayed else {return}
        
        loadVideo()
    }
    
    func requestAds() {
        let adsPlayerVC = IMAVideoPlayerViewController()
        // config
        self.addChild(adsPlayerVC)
        self.view.addSubview(adsPlayerVC.view)
        adsPlayerVC.view.frame = self.view.bounds
        adsPlayerVC.didMove(toParent: self)
        adsPlayerVC.delegate = self
        //ref
        self.imaPlayerVC = adsPlayerVC
    }
    
}


extension VideoDetailViewController: IMAVideoPlayerViewControllerDelegate {
    func didFinsihAds() {
        NSLog("Custom Ads Player didFinish")
        self.imaPlayerVC!.view.removeFromSuperview()
        self.imaPlayerVC!.removeFromParent()
        self.imaPlayerVC = nil
        self.adsHasBeenPlayed = true
        playContentIfReady()
    }
}
