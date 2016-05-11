//
//  ViewController.swift
//  CameraEditor
//
//  Created by Paul Jarysta on 19/04/2016.
//  Copyright © 2016 Paul Jarysta. All rights reserved.
//

import UIKit

enum CropShape {
	case CropShapeRect
	case CropShapeOval
}

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate {
	
	@IBOutlet weak var bgView: UIImageView!
	@IBOutlet weak var imageView: UIImageView!
	
	
	@IBOutlet weak var hideButton: UIBarButtonItem!
	
	@IBOutlet weak var rect_lb: UILabel!
	@IBOutlet weak var oval_lb: UILabel!
	@IBOutlet weak var width_lb: UILabel!
	@IBOutlet weak var height_lb: UILabel!
	
	@IBOutlet weak var widthSlider: UISlider!
	@IBOutlet weak var heightSlider: UISlider!

	let shareData = ShareData.sharedInstance
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor.whiteColor()
		
		shareData.picker = UIImagePickerController()
		shareData.picker!.delegate = self
		
		shareData.shape = .CropShapeRect

		shareData.widthFactor = 1.0
		shareData.heightFactor = 1.0
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loadPhotoCaptured), name: "_UIImagePickerControllerUserDidCaptureItem", object: nil)

		customOutlet()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func customOutlet() {
		width_lb.tag = 3
		height_lb.tag = 4
		
		heightSlider.tag = 1
		heightSlider.minimumValue = 1.0
		heightSlider.maximumValue = 5.0
		
		widthSlider.minimumValue = 1.0
		widthSlider.maximumValue = 5.0
		widthSlider.tag = 2
		
		imageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
	}
	
	func formatNumber (number: Float) -> String? {
		
		let formatter = NSNumberFormatter()
		formatter.maximumFractionDigits = 1
		
		let formattedNumberString = formatter.stringFromNumber(number)
		return formattedNumberString?.stringByReplacingOccurrencesOfString(".00", withString: "")
		
	}
	
	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
		
		shareData.imageSelected = info[UIImagePickerControllerOriginalImage] as? UIImage
		if (shareData.imageSelected != nil) {
			picker.dismissViewControllerAnimated(true, completion: {
				
				let imagePreview: DisplayImageViewController = DisplayImageViewController()
				imagePreview.image = self.shareData.imageSelected
				imagePreview.shareData.widthFactor = self.shareData.widthFactor
				imagePreview.shareData.heightFactor = self.shareData.heightFactor
				imagePreview.shareData.shape = self.shareData.shape
				
				imagePreview.delegate = self
				self.presentViewController(imagePreview, animated: true, completion: nil)
			})
		}
	}
	
	func loadPhotoCaptured() {
		
		var img: UIImage?
		img = self.allImageViewsSubViews((shareData.picker!.viewControllers.first?.view)!).lastObject?.image
		if (img != nil) {
			let imagePicker: UIImagePickerController? = UIImagePickerController()
			
			self.imagePickerController(imagePicker!, didFinishPickingMediaWithInfo: NSDictionary(object: img!, forKey: UIImagePickerControllerOriginalImage) as! [String : AnyObject])
		} else {
			shareData.picker?.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	func croppedImage(image: UIImage) {
		imageView.image = image
		savedImageAlert()
		addBlur(image, backgroundView: bgView)
	}
	
	func addBlur(image: UIImage, backgroundView: UIImageView) {
		let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
		let blurEffectView = UIVisualEffectView(effect: blurEffect)
		blurEffectView.frame = bgView.bounds
		blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight] // for supporting device rotation
		backgroundView.image = image
		backgroundView.addSubview(blurEffectView)
	}

	func savedImageAlert() {
		let alertView = UIAlertView(title: "Saved!", message: "Your picture will be saved to Camera Roll", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "OK")
		
		alertView.tag = 1
		alertView.show()
	}

	func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
		if alertView.tag == 1 {
			if buttonIndex == 0 {
				print("The user is not okay.")
			} else {
				UIImageWriteToSavedPhotosAlbum(imageView.image!, self, nil, nil)
			}
		}
	}
	
	func allImageViewsSubViews(view: UIView) -> NSMutableArray {
		
		let arrImageViews: NSMutableArray = NSMutableArray()
		
		if (view.isKindOfClass(UIImageView.self)) {
			arrImageViews.addObject(view)
		} else {
			for subview: UIView in view.subviews {
				arrImageViews.addObjectsFromArray(self.allImageViewsSubViews(subview) as [AnyObject])
			}
		}
		return arrImageViews
	}
	
	@IBAction func cameraAction(sender: UIBarButtonItem) {
		
		shareData.picker?.sourceType = UIImagePickerControllerSourceType.Camera
		
		self.presentViewController(shareData.picker!, animated:true, completion:nil)
	}
	
	@IBAction func galleryAction(sender: UIBarButtonItem) {
		
		shareData.picker?.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
		
		self.presentViewController(shareData.picker!, animated:true, completion:nil)
	}
	
	@IBAction func hideAction(sender: UIBarButtonItem) {
		imageView.image = nil
	}
	
	@IBAction func formAction(sender: UISwitch) {
		
		if (sender.on) {
			shareData.shape = CropShape.CropShapeOval
		} else {
			shareData.shape = CropShape.CropShapeRect
		}
	}
	
	@IBAction func widthSlider(sender: UISlider) {
		
		if let widthValue = formatNumber(sender.value) {
			width_lb.text = "Width = \(widthValue)"
			shareData.widthFactor = CGFloat(sender.value)
		}
	}
	
	@IBAction func heightSlider(sender: UISlider) {
		
		if let heightValue = formatNumber(sender.value) {
			height_lb.text = "Height = \(heightValue)"
			shareData.heightFactor = CGFloat(sender.value)
		}
	}
}

