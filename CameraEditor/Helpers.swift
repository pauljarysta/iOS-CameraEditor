//
//  Helpers.swift
//  CameraEditor
//
//  Created by Paul Jarysta on 20/04/2016.
//  Copyright © 2016 Paul Jarysta. All rights reserved.
//

import UIKit

class ShareData {
	class var sharedInstance: ShareData {
		struct Static {
			static var instance: ShareData?
			static var token: dispatch_once_t = 0
		}
		
		dispatch_once(&Static.token) {
			Static.instance = ShareData()
		}
		
		return Static.instance!
	}
	
	var picker: UIImagePickerController?

	var imageSelected: UIImage?
	
	var widthFactor: CGFloat?
	var heightFactor: CGFloat?
	var shape: CropShape?
}
