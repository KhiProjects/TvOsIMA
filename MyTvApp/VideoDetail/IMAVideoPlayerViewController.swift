//
//  IMAVideoPlayerViewController.swift
//  ****
//
//  Created by kevin hijlkema on 31/12/2019.
//  Copyright © 2019 Kevin Hijlkema. All rights reserved.
//
import Foundation
import UIKit
import AVKit

//Thrd parties
import GoogleInteractiveMediaAds

// General info
/*
 https://developers.google.com/interactive-media-ads/docs/sdks/ios/
 https://cocoapods.org/pods/GoogleAds-IMA-iOS-SDK
 
 */

protocol IMAVideoPlayerViewControllerDelegate: class {
    func didFinsihAds()
}


class IMAVideoPlayerViewController: UIViewController {
    
    // MARK: - Members
    weak var delegate: IMAVideoPlayerViewControllerDelegate? = nil
    
    // - IMA
    var imaManager: IMAAdsManager? = nil
    var imaLoader: IMAAdsLoader? = nil
    var imaPlayerVC: AVPlayerViewController? = nil
    var imaPlayerHead: IMAAVPlayerContentPlayhead? = nil
    var imaContainer: UIView? = nil
    
    var paused = false
    
    // MARK: - Life Cycle
    deinit {
        removeNotification()
        
        imaManager?.destroy()
        imaManager = nil
        imaLoader = nil
        imaPlayerVC?.player?.pause()
        
        imaPlayerVC?.player = nil
        imaPlayerVC?.removeFromParent()
        imaPlayerVC = nil
        
        imaPlayerHead = nil
        imaContainer?.removeFromSuperview()
        imaContainer = nil
        NSLog("Deinit IMAVideoPlayerViewController ***")
    }
    
    // MARK: - View Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureIMAAdsPlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestAds()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //imaPlayerVC?.player?.pause()
        self.imaManager?.resume()
        removeNotification()
    }
    
    /*
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
     

        event!.allPresses.forEach({ p in
            switch p.type {
            case .menu:
              //  self.imaManager?.resume()
                self.imaManager?.destroy()
                break
            case .playPause:
                if paused {
                    self.imaManager?.start()
                    paused = false
                } else {
                    self.imaManager?.pause()
                    paused = true
                }
                
                break
            case .select:
                self.imaManager?.clicked()
                break
            default:
                break
            }
        })
    }*/
}


extension IMAVideoPlayerViewController: IMAAdsLoaderDelegate, IMAAdsManagerDelegate, IMAStreamManagerDelegate {
    
    //
    func configureIMAAdsPlayer() {
        self.setupIMALoader()
        self.setupIMAPlayer()
        self.setupIMAContainer()
    }
    
    func setupIMALoader() {
        let imaSettings = IMASettings()
        imaSettings.language = "fr"
        imaSettings.enableBackgroundPlayback = true
        imaSettings.disableNowPlayingInfo = true
        
        let loader = IMAAdsLoader(settings: imaSettings)
        loader!.delegate = self
        self.imaLoader = loader
    }
    
    func setupIMAContainer() {
        self.imaContainer = UIView(frame: self.view.bounds)
        self.view.addSubview(self.imaContainer!)
    }
    
    func setupIMAPlayer() {
        // init
        let player = AVPlayer(playerItem: nil)
        let playerVC = AVPlayerViewController.init()
        playerVC.player = player
        // config
        self.addChild(playerVC)
        self.view.addSubview(playerVC.view)
        playerVC.view.frame = self.view.bounds
        playerVC.didMove(toParent: self)
        
        playerVC.delegate = self
        //ref
        self.imaPlayerVC = playerVC
        self.imaPlayerHead = IMAAVPlayerContentPlayhead(avPlayer: player)
        self.catchNotification(forAvPlayer: player)
    }
    
    func requestStream() {
        let container = IMAAdDisplayContainer(adContainer: self.imaContainer!)
        let display = IMAAVPlayerVideoDisplay(avPlayer: self.imaPlayerVC!.player!)

        #if false
        let request = IMALiveStreamRequest(assetKey: /*self.adInfo!.identifier!*/"sN_IYUG8STe1ZzhIIE_ksA",
                                           adDisplayContainer: container,
                                           videoDisplay: display)!
        #else
        let request = IMAVODStreamRequest(contentSourceID: "19463",
                                          videoID: "googleio-highlights",
                                          adDisplayContainer: container,
                                          videoDisplay: display)
        #endif
         self.imaLoader!.requestStream(with: request)
    }
    func requestAds() {
        let container = IMAAdDisplayContainer(adContainer: self.imaContainer!)

        let tag: String = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&" +
                "iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&" +
                "output=vast&unviewed_position_start=1&" +
        "cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
        
        let request = IMAAdsRequest(adTagUrl: tag,
                                    adDisplayContainer: container,
                                    contentPlayhead: self.imaPlayerHead!,
                                    userContext: nil)
        self.imaLoader!.requestAds(with: request!)

    }
    
    
    func catchNotification(forAvPlayer contentPlayer: AVPlayer) {
        NotificationCenter.default.addObserver(
        self,
        selector: #selector(IMAVideoPlayerViewController.contentDidFinishPlaying(notification:)),
        name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
        object: contentPlayer.currentItem);
    }
    
    func removeNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func contentDidFinishPlaying(notification: NSNotification) {
        // Make sure we don't call contentComplete as a result of an ad completing.
        if ((notification.object as! AVPlayerItem) == self.imaPlayerVC!.player!.currentItem) {
            // NOTE: This line will cause an error until the next step, "Request Ads".
            self.imaLoader!.contentComplete()
        }
    }
    
    
    // MARK: - IMAAdsLoaderDelegate
    func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        NSLog("IMAAdsLoader: adsLoadedWith \(adsLoadedData.debugDescription)")
        
        // Grab the instance of the IMAAdsManager and set ourselves as the delegate
        imaManager = adsLoadedData.adsManager
        imaManager!.delegate = self
        
        // Create ads rendering settings and tell the SDK to use the in-app browser.
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.webOpenerPresentingController = self
        
        // Initialize the ads manager.
        imaManager!.initialize(with: adsRenderingSettings)
    }
    
    func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        NSLog("IMAAdsLoader: failedWith \(adErrorData.debugDescription)")
        
        self.delegate?.didFinsihAds() // WithError
    }
    
    // MARK: - IMAAdsManagerDelegate
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        NSLog("IMAAdsManager: didReceive event \(event.debugDescription)")
        if (event.type == IMAAdEventType.LOADED) {
            // When the SDK notifies us that ads have been loaded, play them.
            adsManager.start()
            self.paused = false
        }
    }
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        NSLog("IMAAdsManager: didReceive error \(error.debugDescription)")
        
        adsManager.destroy()
        self.delegate?.didFinsihAds() // WithError
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        NSLog("IMAAdsManager: adsManagerDidRequestContentPause ")
        
        //    contentPlayer!.pause()
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        NSLog("IMAAdsManager: adsManagerDidRequestContentResume ")
        
        //    contentPlayer!.play()
        adsManager.destroy()
        imaLoader!.contentComplete()
        self.delegate?.didFinsihAds() // 
    }
    
    // MARK: - IMAStreamManagerDelegate
    func streamManager(_ streamManager: IMAStreamManager!, didReceive event: IMAAdEvent!) {
        NSLog("IMAStreamManager: didReceive \(event.debugDescription)")
    }
    
    func streamManager(_ streamManager: IMAStreamManager!, didReceive error: IMAAdError!) {
        NSLog("IMAStreamManager: didReceive \(error.debugDescription)")
    }
}


extension IMAVideoPlayerViewController: AVPlayerViewControllerDelegate {
    func playerViewController(_ playerViewController: AVPlayerViewController, didAccept proposal: AVContentProposal) {
        NSLog("IMAVideoPlayerViewController - playerViewController: didAccept proposal \(proposal.debugDescription)")
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, didPresent interstitial: AVInterstitialTimeRange) {
        NSLog("IMAVideoPlayerViewController - playerViewController: didPresent interstitial \(interstitial.debugDescription)")
    }
}
