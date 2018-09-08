//
//  ViewController.swift
//  PhotoDemo
//
//  Created by aby on 2018/9/7.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

struct Input: MVVMInput {
    init(view: MVVMView) {
        let view = view as! ViewController
        imageDriver = view.imageSubject.asDriver(onErrorJustReturn: (UIImage.init(), ""))
        imageSelected = view.totalCollection.rx.itemSelected.asDriver()
        let isScrollEnd = view.detailCollection.rx.didEndDecelerating.map { () -> Bool in
            let scrollview = view.detailCollection
            let result = !scrollview.isTracking && !scrollview.isDragging && !scrollview.isDecelerating
            return result
            }.filter { (isEnd) -> Bool in
                
                return isEnd
        }.asDriver(onErrorJustReturn: false)
        imageScroll = Driver.combineLatest(view.detailCollection.rx.contentOffset.asDriver(), isScrollEnd, resultSelector: { (point, scrollEnd) -> CGPoint in
            return point
        })
    }
    let imageScroll: Driver<CGPoint>
    let imageDriver: Driver<(UIImage, String)>
    let imageSelected: Driver<IndexPath>
    let reloadCommand: PublishSubject<Bool> = PublishSubject<Bool>.init()
}

class ViewController: MVVMView {
    lazy var detailCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.itemSize = CGSize.init(width: view.width, height: view.height * 3 / 4)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.minimumLineSpacing = 0
        let collection = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        collection.backgroundColor = UIColor.black
        collection.scrollsToTop = false
        collection.isPagingEnabled = true
        collection.register(DetailCollectionCell.self, forCellWithReuseIdentifier: DetailCollectionCell.cellID)
        return  collection
    }()
    
    lazy var totalCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.itemSize = CGSize.init(width: (view.height / 4 - 60), height: view.height / 4 - 60)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.minimumLineSpacing = 15
        let collection = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        collection.backgroundColor = UIColor.black
        collection.scrollsToTop = false
        collection.isPagingEnabled = false
        collection.showsHorizontalScrollIndicator = false
        collection.register(TotalCollectionCell.self, forCellWithReuseIdentifier: TotalCollectionCell.cellID)
//        collection.rx.setDelegate(self).disposed(by: disposeBag)
        return collection
    }()
    
    override var inputType: MVVMInput.Type? { return Input.self }
    var imageSubject = PublishSubject<(UIImage, String)>.init()
    // MARK: -MVVM
    override func rxDrive(viewModelOutput: MVVMOutput) {
        let outPut = viewModelOutput as! OutPut
        outPut.imageArrDriver.drive(detailCollection.rx.items(cellIdentifier: DetailCollectionCell.cellID, cellType: DetailCollectionCell.self)) {(row, element, cell) in
            cell.imageView.image = element.1
            cell.nameLabel.text = element.0
            cell.tap.rx.event.asControlEvent().subscribe(onNext: { (tap) in
                let imageVC = ImgeDetailViewController()
                imageVC.image = element.1
                self.present(imageVC, animated: false, completion: nil)
            }).disposed(by: cell.disposeBag)
            cell.longTap.rx.event.asControlEvent().subscribe(onNext: { (tap) in
                // FIXME: 长按删除
            }).disposed(by: cell.disposeBag)
        }.disposed(by: disposeBag)
        outPut.totalImageArrDriver
            .drive(totalCollection.rx.items(cellIdentifier: TotalCollectionCell.cellID, cellType: TotalCollectionCell.self)) {(row, element, cell) in
                cell.isCurrent = element.0
                cell.imageView.image = element.1
        }.disposed(by: disposeBag)
        totalCollection.rx.willDisplayCell.asDriver().drive(onNext: { (cell, indexpath) in
            let totalCell = cell as! TotalCollectionCell
            totalCell.startAnimation()
        }).disposed(by: disposeBag)
        outPut.imageScrollDriver.drive(onNext: { (index) in
            guard index >= 0 else { return }
            self.detailCollection.scrollToItem(at: IndexPath.init(row: index, section: 0), at: .centeredHorizontally, animated: true)
        }).disposed(by: disposeBag)
        outPut.scrollLeft.drive(onNext: { (index) in
            guard index >= 0 else { return }
            self.totalCollection.scrollToItem(at: IndexPath.init(row: index, section: 0), at: .left, animated: true)
        }).disposed(by: disposeBag)
    }
    // MARK: - View 的基本设置
    func makeViewSetting() -> Void {
        title = "相册Demo"
        view.backgroundColor = UIColor.hexInt(0xf5f5f5)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        makeViewSetting()
        makeConstraints()
        (self.viewModel?.input as! Input).reloadCommand.onNext(true)
        self.createRightBtnItem(icon: #imageLiteral(resourceName: "cream").withRenderingMode(.alwaysOriginal))
            .drive(onNext: { () in
                DTLog("点击打开相册按钮")
                self.openCrame() // 打开相册相关
            }).disposed(by: disposeBag)
    }
}

extension ViewController {
    private func makeConstraints() {
        view.addSubview(detailCollection)
        view.addSubview(totalCollection)
        detailCollection.snp.makeConstraints { (make) in
            make.top.right.left.equalTo(view)
            make.height.equalTo(view.height * 3 / 4)
        }
        totalCollection.snp.makeConstraints { (make) in
            make.bottom.left.right.equalTo(view)
            make.height.equalTo(view).dividedBy(4)
        }
    }
}


// MARK: - 相册相机相关操作
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func openCrame() -> Void {
        let picker: UIImagePickerController = UIImagePickerController.init()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            self.present(picker, animated: true) {
                
            }
        } else {
            // FIXME: 添加打开权限的提示
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // 取消选择的代理
        picker.dismiss(animated: true) {
            
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // 选择成功后的代理
        if let chosenImage =  info[UIImagePickerControllerOriginalImage] as? UIImage {
            let pickUrl = info[UIImagePickerControllerImageURL] as!URL
            let imageName = pickUrl.lastPathComponent
            picker.dismiss(animated: true) {
               self.imageSubject.onNext((chosenImage, imageName))
            }
        }
    }
}
