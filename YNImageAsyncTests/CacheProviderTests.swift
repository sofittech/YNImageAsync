//
//  CacheProviderTests.swift
//  ImageAsyncTest
//
//  Created by Yury Nechaev on 2016-10-21.
//  Copyright © 2016 Yury Nechaev. All rights reserved.
//

import XCTest
@testable import YNImageAsync

class CacheProviderTests: XCTestCase {
    
    var cacheProvider : CacheProvider? = nil
    let imageNames = ["mountains.jpg", "parrot-indian.jpg", "parrot.jpg", "saint-petersburg.jpg", "snow.jpg", "tiger.jpg"]

    override func setUp() {
        super.setUp()
        cacheProvider = CacheProvider(configuration: CacheConfiguration(options: [.memory, .disk], memoryCacheLimit: 30 * 1024 * 1024)) // enough to store all images
        cacheProvider?.clearCache()
        for img in imageNames {
            if let image = UIImage(named: img, in: Bundle(for: type(of: self)), compatibleWith: nil) {
                if let imageData = image.jpegData(compressionQuality: 0.9) {
                    let exp = expectation(description: img)
                    cacheProvider?.cacheData(img, imageData, completion: { (success) -> (Void) in
                        exp.fulfill()
                    })
                    waitForExpectations(timeout: 10, handler: nil)
                }
            }
        }
    }
    
    func testCacheForKey() {
        for image in imageNames {
            let imageExpectation = expectation(description: image)
            guard let provider = cacheProvider else {
                XCTFail("Failed to get cache provider")
                return
            }
            provider.cacheForKey(image, completion: { (data) in
                XCTAssertNotNil(data, "Cache data is nil")
                imageExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 10) { (error) in
            print(error ?? "Wait timeout")
        }
    }
    
    func testMemoryCacheForKey() {
        for image in imageNames {
            guard let provider = cacheProvider else {
                XCTFail("Failed to get cache provider")
                return
            }
            guard let _ = provider.memoryCache[image] else {
                XCTFail("Can not retrieve \(image) image from memory cache")
                return
            }
        }
    }
    
    func testDiskCacheForKey() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        provider.configuration.options = .disk
        for image in imageNames {
            let diskExpectation = expectation(description: image + "disk")
            _ = provider.diskCacheForKey(image, completion: { (data) in
                XCTAssertNotNil(data, "Disk cache data is nil for key: \(image)")
                diskExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 10) { (error) in
            print(error ?? "Wait timeout")
        }

        provider.configuration.options = .memory
        for image in imageNames {
            let memoryExpectation = expectation(description: image + "memory")
            _ = provider.diskCacheForKey(image, completion: { (data) in
                XCTAssertNil(data, "Disk cache data not nil for key: \(image)")
                memoryExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 10) { (error) in
            print(error ?? "Wait timeout")
        }
        
    }
    
    func testCacheData() {
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        for image in imageNames {
            let cacheExpectation = expectation(description: image)
            provider.cacheForKey(image, completion: { (data) in
                XCTAssertTrue(data != nil)
                cacheExpectation.fulfill()
            })
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
    
    func testCacheDataToMemory() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        provider.memoryCache.removeAll()
        
        provider.configuration.options = .memory
        for img in imageNames {
            if let image = UIImage(named: img, in: Bundle(for: type(of: self)), compatibleWith: nil) {
                let imageData = image.jpegData(compressionQuality: 0.9)
                cacheProvider?.cacheDataToMemory(img, imageData!)
            }
        }
        for image in imageNames {
            XCTAssertNotNil(provider.memoryCacheForKey(image))
        }
        
        provider.memoryCache.removeAll()

        provider.configuration.options = .disk

        for img in imageNames {
            if let image = UIImage(named: img, in: Bundle(for: type(of: self)), compatibleWith: nil) {
                let imageData = image.jpegData(compressionQuality: 0.9)
                cacheProvider?.cacheDataToMemory(img, imageData!)
            }
        }
        
        for image in imageNames {
            XCTAssertNil(provider.memoryCacheForKey(image))
        }
    }
    
    func testCacheDataToDisk() {
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        provider.memoryCache.removeAll()
        
        provider.configuration.options = .memory
        for img in imageNames {
            if let image = UIImage(named: img, in: Bundle(for: type(of: self)), compatibleWith: nil) {
                let imageData = image.jpegData(compressionQuality: 0.9)
                cacheProvider?.cacheDataToMemory(img, imageData!)
            }
        }
        for image in imageNames {
            XCTAssertNotNil(provider.memoryCacheForKey(image))
        }
        
        provider.memoryCache.removeAll()
        
        provider.configuration.options = .disk
        
        for img in imageNames {
            if let image = UIImage(named: img, in: Bundle(for: type(of: self)), compatibleWith: nil) {
                let imageData = image.jpegData(compressionQuality: 0.9)
                cacheProvider?.cacheDataToMemory(img, imageData!)
            }
        }
        
        for image in imageNames {
            XCTAssertNil(provider.memoryCacheForKey(image))
        }
    }
    
    func testCleanMemoryCache() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        let newLimit: Int64 = 10 * 1024 * 1024
        
        XCTAssertTrue(provider.memoryCache.count == imageNames.count)
        
        provider.configuration.memoryCacheLimit = newLimit
        provider.cleanMemoryCache()
        
        XCTAssertTrue(provider.memoryCache.count == 3)
        XCTAssertTrue(provider.memoryCacheSize() <= newLimit)
    }
    
    func testClearMemoryCache() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        XCTAssertTrue(provider.memoryCache.count == imageNames.count)
        
        provider.clearMemoryCache()
        
        XCTAssertTrue(provider.memoryCache.count == 0)
    }
    
    func testDiskCacheSize() {
        
        let accuracy : Double = 0.10 // we expect less than 10% value difference
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        var calculatedSize : Int64 = 0
        for img in imageNames {
            if let image = UIImage(named: img, in: Bundle(for: type(of: self)), compatibleWith: nil) {
                if let imageData = image.jpegData(compressionQuality: 0.9) {
                    calculatedSize += Int64(imageData.count)
                }
            }
        }
        
        let diskSize = provider.diskCacheSize()
        let difference = Double(calculatedSize) / Double(diskSize)
        
        XCTAssertTrue(difference > (1 - accuracy))
    }
    
    func testMemoryCacheSize() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        var calculatedSize : Int64 = 0
        for img in imageNames {
            if let image = UIImage(named: img, in: Bundle(for: type(of: self)), compatibleWith: nil) {
                if let imageData = image.jpegData(compressionQuality: 0.9) {
                    calculatedSize += Int64(imageData.count)
                }
            }
        }
        
        let memorySize = provider.memoryCacheSize()
        XCTAssertTrue(memorySize == calculatedSize)
    }
    
    func testClearDiskCache() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        XCTAssertTrue(provider.cacheFolderFiles().count == imageNames.count)
        provider.clearDiskCache()
        XCTAssertTrue(provider.cacheFolderFiles().count == 0)
        
    }
    
    func testClearCache() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        XCTAssertTrue(provider.memoryCacheSize() > 0)
        XCTAssertTrue(provider.diskCacheSize() > 0)
        
        provider.clearCache()
        
        XCTAssertTrue(provider.memoryCacheSize() == 0)
        XCTAssertTrue(provider.diskCacheSize() == 0)

    }
    
    func testCacheFolderFiles() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        let files = provider.cacheFolderFiles()
        
        XCTAssertTrue(imageNames.count == files.count, "Disk cache count \(files.count) != images count \(imageNames.count)")
    }
    
    func testFilterCacheWithArray() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        XCTAssertTrue(provider.memoryCache.keys.count == imageNames.count)
        
        let filter : Array<CacheEntry> = [provider.memoryCache.first!.value]
        provider.filterCacheWithArray(array: filter)
        
        XCTAssertTrue(provider.memoryCache.keys.count == 1)
    }
    
    func testCacheDirectory() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        let directory = provider.cacheDirectory()
        let url = URL(fileURLWithPath: directory, isDirectory: true)
        XCTAssertTrue(url.isFileURL)
    }
    
    func testCachePath() {
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        let path = provider.cachePath()
        let url = URL(fileURLWithPath: path, isDirectory: true)
        XCTAssertTrue(url.isFileURL)
        XCTAssertTrue(path.contains("YNImageAsync"))
    }
    
    func testFileInCacheDirectory() {
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        let file = imageNames.first!
        let path = provider.fileInCacheDirectory(filename: file)
        let url = URL(fileURLWithPath: path, isDirectory: true)
        XCTAssertTrue(url.isFileURL)
        XCTAssertTrue(path.contains(file))
    }
    
    func testReadCache() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        
        for image in imageNames {
            let cacheExpectation = expectation(description: image)
            let filePath = provider.fileInCacheDirectory(filename: image)
            let url = URL(fileURLWithPath: filePath)
            _ = provider.readCache(fileUrl: url, completion: { (data) in
                XCTAssertNotNil(data, "Disk cache data is nil")
                cacheExpectation.fulfill()
            })
        }
        waitForExpectations(timeout: 10) { (error) in
            print(error ?? "Wait timeout")
        }
    }
    
    func testSaveCache() {
        
        guard let provider = cacheProvider else {
            XCTFail("Failed to get cache provider")
            return
        }
        provider.clearDiskCache()
        XCTAssertTrue(provider.cacheFolderFiles().count == 0, "Unable to clean cache folder")
        
        let file = imageNames.first!
        let filePath = provider.fileInCacheDirectory(filename: file)
        let url = URL(fileURLWithPath: filePath)

        if let image = UIImage(named: file, in: Bundle(for: type(of: self)), compatibleWith: nil) {
            if let imageData = image.jpegData(compressionQuality: 0.9) {
                provider.saveCache(cacheData: imageData, fileUrl: url)
                let files = provider.cacheFolderFiles()
                XCTAssertTrue(files.count == 1)
            } else {
                XCTFail("Can not create image data: \(file)")
            }
        } else {
            XCTFail("Can not load image from bundle: \(file)")
        }
    }
    
}
