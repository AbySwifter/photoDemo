//
//  DetailCollectionCell.swift
//  PhotoDemo
//
//  Created by aby on 2018/9/7.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit
import RxSwift

class DetailCollectionCell: UICollectionViewCell {
    static let cellID = "DetailCollectionCell"
    let imageView = UIImageView.init(frame: CGRect.zero)
    let nameLabel = UILabel.init(frame: CGRect.zero)
    let tap = UITapGestureRecognizer.init()
    let longTap = UILongPressGestureRecognizer.init()
    let disposeBag = DisposeBag.init()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.removeFromSuperview()
        makeStyle()
        makeConstraints()
    }
    
    private func makeConstraints() {
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(self)
        }
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(self)
            make.width.lessThanOrEqualToSuperview().dividedBy(2)
        }
    }
    
    private func makeStyle() {
        imageView.backgroundColor = UIColor.black
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tap)
        imageView.addGestureRecognizer(longTap)
        nameLabel.textColor = UIColor.white
        nameLabel.numberOfLines = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
