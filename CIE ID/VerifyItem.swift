//
//  VerifyItem.swift
//  CIE ID
//
//

import Foundation

@objc
class VerifyItem : NSObject{
     
    private (set) var img : NSImage
    @objc
    var enlarge = false
    @objc
    var value : String
    
    @objc
    init(image: NSImage, value : String)
    {
        
        self.value = value
        self.img = image
    }
    
    /*
    @objc
    func setEnlarge(_ flag : Bool)
    {
        self.enlarge = flag
    }
   */
}
