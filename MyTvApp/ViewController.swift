//
//  ViewController.swift
//  MyTvApp
//
//  Created by kevin hijlkema on 08/01/2020.
//  Copyright © 2020 KhiProjects. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    var modeAds: Bool = true

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showVideoPlayerSegue" else {return}
        guard let vc = segue.destination as? VideoDetailViewController else {return}
        
        vc.configure(withAds: self.modeAds)
        //DO Something with it
    }
    
    @IBAction func didClickOn(_ sender: UISegmentedControl) {
        self.modeAds = sender.selectedSegmentIndex == 0 ? true : false
    }
}

