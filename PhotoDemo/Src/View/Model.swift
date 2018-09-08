//
//  Model.swift
//  PhotoDemo
//
//  Created by aby on 2018/9/7.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit


struct Model {
    var imageArr: [ImageInfo] = []
    var falanyIndex: Int {
        return imageArr.count - 1
    }
    
    init() {
        loadFromDatabase() // 从数据库加载
    }
    
    // 保存数据库
    mutating func loadFromDatabase() {
        guard let realm = DataBaseManager.instance.realm else {
            return
        }
        self.imageArr.removeAll()
        let images = realm.objects(ImageSchema.self)
        for item in images {
            let info = ImageInfo.init(dataBase: item)
            self.imageArr.append(info)
        }
    }
    // 加载数据库
}

struct ImageInfo {
    var identify: String
    var name: String
    var image: UIImage
    var thumb: UIImage
    var path: String
    
    func saveToDataBase() -> Void {
        let obj = self.toObject()
        guard let realm = DataBaseManager.instance.realm else {
            return
        }
        try? realm.write {
            realm.add(obj)
        }
    }
    
    mutating func save() -> Void {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let filePath = paths.first! + "/" + self.name
        guard let imageData = UIImagePNGRepresentation(self.image) as NSData? else { return }
        let result = imageData.write(toFile: filePath, atomically: true)
        DTLog("保存结果：\(result)") // 保存结果
        if result {
            self.path = filePath
        }
    }
    
    init(name: String, image: UIImage) {
        self.name = name
        self.image = image
        self.identify = image.newGUID()
        self.path = ""
        self.thumb = image.setThumbnail()
        self.save()
    }
    
    init(dataBase item: ImageSchema) {
        self.identify = item.identify
        self.path = item.path
        self.name = item.name
        self.image = UIImage.init()
        self.thumb = UIImage.init()
        self.load()
    }
    
    mutating func load() -> Void {
//        guard self.path != "" else { return }
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let filePath = paths.first! + "/" + self.name
        guard let image = UIImage.init(contentsOfFile: filePath) else {
            // 文件不存在
            self.path = ""
            DTLog("文件不存在")
            return
        }
        self.image = image
        self.thumb = image.setThumbnail()
    }
    
    mutating func delete() -> Void {
        guard self.path != "" else { return }
        do {
            try FileManager.default.removeItem(atPath: self.path)
            // 删除成功
            self.path = ""
        } catch let error {
            DTLog(error)
        }
    }
    
    func toObject() -> ImageSchema {
        let obj = ImageSchema.init()
        obj.identify = self.identify
        obj.name = self.name
        obj.path = self.path
        return obj
    }
}
