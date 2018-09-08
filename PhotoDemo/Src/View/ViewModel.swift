//
//  ViewModel.swift
//  PhotoDemo
//
//  Created by aby on 2018/9/7.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

struct OutPut: MVVMOutput {
    init(viewModel: MVVMViewModel) {
        let vm = viewModel as! ViewModel
        let input = vm.input as! Input
        input.imageDriver.drive(onNext: { (info) in
            vm.add(imageInfo: info)
        }).disposed(by: vm.bag)
        imageArrDriver = vm.modelRelay.asDriver().map({ (model) -> [(String, UIImage)] in
            return model.imageArr.map({ (info) -> (String, UIImage) in
                return (info.name, info.image)
            })
        })
        totalImageArrDriver = Driver.combineLatest(vm.currentIndexRelay.filter({ $0 >= 0 }).asDriver(onErrorJustReturn: 0), vm.modelRelay.asDriver(), resultSelector: { (index, model) -> [(Bool, UIImage)] in
            let array = model.imageArr.map({ (imageInfo) -> (Bool, UIImage) in
                let isSelected = model.imageArr[index].identify == imageInfo.identify
                DTLog(isSelected)
                return (isSelected, imageInfo.thumb)
            })
            return array
        })
        imageScrollDriver = vm.scrollCommond.asDriver(onErrorJustReturn: -1)
        currentIndexDriver = vm.currentIndexRelay.asDriver()
        scrollLeft = Driver.combineLatest(vm.currentIndexRelay.asDriver(), vm.needTotalScroll.asDriver(onErrorJustReturn: false).filter({ $0 }), resultSelector: { (index, need) -> Int in
            return index
        })
        bind(vm: vm)
    }
    // 数据源
    let imageArrDriver: Driver<[(String, UIImage)]>
    let totalImageArrDriver: Driver<[(Bool, UIImage)]>
    // 滚动动作
    let imageScrollDriver: Driver<Int>
    let currentIndexDriver: Driver<Int>
    let scrollLeft: Driver<Int>
    // 增加
    func bind(vm: ViewModel) {
        let input = vm.input as! Input
        input.imageScroll.drive(onNext: { (point) in
            vm.scrollTo(point: point)
        }).disposed(by: vm.bag)
        input.imageSelected.map { (indexPath) -> Int in
            return indexPath.row
        }.drive(vm.scrollCommond).disposed(by: vm.bag)
    }
}

class ViewModel: MVVMViewModel {
    override var outputType: MVVMOutput.Type? { return OutPut.self }
    required init(input: MVVMInput) {
        super.init(input: input)
        self.delyScroll.delay(0.5, scheduler: MainScheduler.instance).bind { (index) in
            self.scrollCommond.onNext(index)
            }.disposed(by: bag)
        let i = input as! Input
        i.reloadCommand.asDriver(onErrorJustReturn: false).drive(onNext: { (isReload) in
            if isReload {
                var model = self.modelRelay.value
                model.loadFromDatabase()
                self.modelRelay.accept(model)
                self.currentIndexRelay.accept(model.falanyIndex != -1 ? 0 : -1)
            }
        }).disposed(by: bag)
        i.imageSelected.map { (indexPath) -> Int in
            self.needTotalScroll.onNext(false)
            return indexPath.row
        }.drive(currentIndexRelay).disposed(by: bag)
    }
    var currentIndexRelay = BehaviorRelay<Int>.init(value: -1)
    var scrollCommond = PublishSubject<Int>.init()
    var modelRelay = BehaviorRelay<Model>.init(value: Model.init())
    var delyScroll = PublishSubject<Int>.init()
    var needTotalScroll = PublishSubject<Bool>.init()
    func add(imageInfo: (UIImage, String)) -> Void {
        var model = modelRelay.value
        let info = ImageInfo.init(name: imageInfo.1, image: imageInfo.0)
        info.saveToDataBase()
        model.imageArr.append(info)
        modelRelay.accept(model)
        currentIndexRelay.accept(model.falanyIndex)
        delyScroll.onNext(model.falanyIndex)
    }
    
    func deleteImage() -> Void {
        
    }
    
    func scrollTo(point: CGPoint) {
        let page = Int(point.x / UIScreen.main.bounds.width)
        if page != currentIndexRelay.value && modelRelay.value.falanyIndex >= 0 {
            currentIndexRelay.accept(page)
            needTotalScroll.onNext(true)
        }
    }
}


// 缩放图片的方法
extension UIImage {
    func setThumbnail() -> UIImage {
        let originSize = self.size
        let newRect = CGRect.init(x: 0, y: 0, width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(newRect.size, false, 0.0)
        let ratio = CGFloat.maximum(newRect.width / originSize.width, newRect.height / originSize.height)
        let path = UIBezierPath.init(rect: newRect)
        path.addClip()
        var projectRect = CGRect.init()
        projectRect.size.width = originSize.width * ratio
        projectRect.size.height = originSize.height * ratio
        projectRect.origin.x = (newRect.width - projectRect.width) / 2
        projectRect.origin.y = (newRect.height - projectRect.height) / 2
        
        self.draw(in: projectRect)
        let target = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let result = target else { return UIImage.init() }
        return result
    }
    
    // 生成随机字符串
    func newGUID(length: Int = 30) -> String {
        let characters = "0123456789abcdef"
        var ranStr = ""
        for _ in 0..<length {
            let index = Int(arc4random_uniform(16))
            ranStr.append(characters[characters.index(characters.startIndex, offsetBy: index)])
        }
        return ranStr
    }
}
