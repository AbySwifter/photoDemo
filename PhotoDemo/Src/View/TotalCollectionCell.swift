//
//  TotalCollectionCell.swift
//  PhotoDemo
//
//  Created by aby on 2018/9/7.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit

class TotalCollectionCell: UICollectionViewCell {
    static let cellID = "TotalCollectionCell"
    var imageView: UIImageView = UIImageView.init(frame: CGRect.zero)
    var isCurrent: Bool = false
    private var currentStatus: Bool = false // 记录当前选中状态
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.removeFromSuperview()
        makeStyle()
        makeConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func startAnimation() -> Void {
        guard self.isCurrent != self.currentStatus else {
            return
        }
        self.isCurrent ? selectedAnimation() : unSelectedAnimation()
    }
    
    private func selectedAnimation() -> Void {
        UIView.animate(withDuration: 0.3, animations: {
            self.imageView.snp.remakeConstraints({ (make) in
                make.top.left.equalTo(self)
                make.right.equalTo(self)
                make.bottom.equalTo(self)
            })
            self.layoutIfNeeded()
        }) { (complete) in
            self.currentStatus = true
        }
    }
    
    private func unSelectedAnimation() -> Void {
        UIView.animate(withDuration: 0.3, animations: {
            self.imageView.snp.remakeConstraints({ (make) in
                make.top.left.equalTo(self).offset(10)
                make.right.equalTo(self).offset(-10)
                make.bottom.equalTo(self)
            })
            self.layoutIfNeeded()
        }) { (complete) in
            self.currentStatus = false
        }
    }
    
    private func makeConstraints() {
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.left.equalTo(self).offset(10)
            make.right.equalTo(self).offset(-10)
            make.bottom.equalTo(self)
        }
    }
    
    private func makeStyle() {
        imageView.backgroundColor = UIColor.black
        imageView.contentMode = .scaleAspectFit
    }
}
