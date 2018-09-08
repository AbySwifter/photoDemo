//
//  ImgeDetailViewController.swift
//  PhotoDemo
//
//  Created by aby on 2018/9/8.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit
import SnapKit

class ImgeDetailViewController: UIViewController {

    lazy var imageView: UIImageView = {
        let imageV: UIImageView = UIImageView.init(frame: self.view.bounds)
        imageV.isUserInteractionEnabled = true
        imageV.contentMode = .scaleAspectFit
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(dismissSelf))
        imageV.addGestureRecognizer(tap)
        return imageV
    }()
    
    var image: UIImage = UIImage.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        view.backgroundColor = UIColor.darkGray
        imageView.image = image
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func dismissSelf() {
        self.dismiss(animated: false) {

        }
    }

}
