//
//  DisplayImageViewController.swift
//  CameraEditor
//
//  Created by Paul Jarysta on 19/04/2016.
//  Copyright © 2016 Paul Jarysta. All rights reserved.
//

import UIKit

class DisplayImageViewController: UIViewController, UIScrollViewDelegate {
	
	let shareData = ShareData.sharedInstance
	
	var scrollView: UIScrollView?
	
	var imageView: UIImageView?
	var cropRect: CGRect?
	
	var image: UIImage?

	var delegate: AnyObject?
	
	var cropBezierPath: UIBezierPath!
	
	var transparentImageMaskView: UIImageView?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if let width = shareData.widthFactor, height = shareData.heightFactor {
			self.applyCropWithWidth(width, heightFactor: height)
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func applyCropWithWidth(widthFactor: CGFloat, heightFactor: CGFloat) {
		
		var imageRect: CGRect = view.bounds
		let fSmallerSide: CGFloat = imageRect.size.width < imageRect.size.height ? imageRect.size.width : imageRect.size.height
		
		if widthFactor >= heightFactor {
			cropRect = CGRectMake(0, (imageRect.size.height - (heightFactor * imageRect.size.width / widthFactor)) / 2.0, imageRect.size.width, heightFactor * imageRect.size.width / widthFactor)
		} else {
			cropRect = CGRectMake((imageRect.size.width - (imageRect.size.height * widthFactor / heightFactor)) / 2.0, 0, imageRect.size.height * widthFactor / heightFactor, imageRect.size.height )
		}
		imageRect = cropRect!
		
		let aspectRatio: CGFloat? = self.image!.size.width / self.image!.size.height
		let zoomScale: CGFloat!
		
		if (aspectRatio > 1) //Landscape Image
		{
			imageRect.size.width = fSmallerSide * aspectRatio!
			imageRect.size.height = fSmallerSide
			zoomScale = cropRect!.size.height / imageRect.size.height
		} else {
			imageRect.size.width = fSmallerSide
			imageRect.size.height = fSmallerSide / aspectRatio!
			zoomScale = imageRect.size.width / cropRect!.size.width
		}
		
		scrollView = UIScrollView(frame: self.view.bounds)
		scrollView?.clipsToBounds = false
		scrollView?.bounces = true
		scrollView?.showsHorizontalScrollIndicator = false
		scrollView?.showsVerticalScrollIndicator = false
		scrollView?.minimumZoomScale = 1
		scrollView?.maximumZoomScale = 100
		scrollView?.delegate = self
		scrollView?.contentInset = UIEdgeInsetsMake(imageRect.origin.y, imageRect.origin.x, (scrollView?.bounds.size.height)! - cropRect!.size.height - imageRect.origin.y, (scrollView?.bounds.size.width)! - cropRect!.size.width - cropRect!.origin.x)
		self.view.addSubview(scrollView!)
		
		let imageView: UIImageView = UIImageView(image: image)
		imageView.contentMode = UIViewContentMode.ScaleAspectFit
		imageView.frame = CGRectMake(0, 0, imageRect.size.width, imageRect.size.height)
		scrollView?.addSubview(imageView)

		view.insertSubview(transparentMaskView(), aboveSubview: scrollView!)

		if let zoom = zoomScale {
			print(zoom)
			scrollView?.zoomScale = zoom
			scrollView?.maximumZoomScale = zoom
			scrollView?.maximumZoomScale = zoom * 2
		}
		
		let bottombuttonView: UIView = UIView(frame: CGRectMake(0, 20, self.view.bounds.size.width, 40))
		bottombuttonView.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin
		bottombuttonView.tag = 1234
		view.addSubview(bottombuttonView)
		
		let cancel: UIButton = UIButton(frame: CGRectMake(10, 0, 60, 40))
		cancel.setTitle("Cancel", forState: UIControlState.Normal)
		cancel.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
		cancel.enabled = true
		cancel.addTarget(self, action: #selector(cancelAction), forControlEvents: UIControlEvents.TouchUpInside)
		bottombuttonView.addSubview(cancel)
		
		let done: UIButton = UIButton(frame: CGRectMake(bottombuttonView.bounds.size.width - 60 - 10, 0, 60, 40))
		done.setTitle("Done", forState: UIControlState.Normal)
		done.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
		done.addTarget(self, action: #selector(doneAction), forControlEvents: UIControlEvents.TouchUpInside)
		bottombuttonView.addSubview(done)
	}
	
	func transparentMaskView() -> UIImageView {
		if (transparentImageMaskView == nil) {
			transparentImageMaskView = UIImageView(image: transparentImage())
			transparentImageMaskView!.userInteractionEnabled = false
		}
		return transparentImageMaskView!
	}
	
	func transparentImage() -> UIImage {
		
		let bounds: CGRect = self.view.bounds
		
		UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0);
		
		let clipPath: UIBezierPath = UIBezierPath(rect: bounds)
		
		if shareData.shape == .CropShapeRect {
			cropBezierPath = UIBezierPath(rect: cropRect!)
		} else {
			cropBezierPath = UIBezierPath(ovalInRect: cropRect!)
		}
		
		if let cropBezier = cropBezierPath {
			clipPath.appendPath(cropBezier)
			clipPath.usesEvenOddFillRule = true
			
			UIColor(white: 0, alpha: 0.5).setFill()
			clipPath.fill()
			
			cropBezier.lineWidth = 0.5
			UIColor.whiteColor().setStroke()
			cropBezier.stroke()
		}
		
		let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image!
	}
	
	func getImageInRect(visibleRect: CGRect) -> UIImage {
		UIGraphicsBeginImageContext(visibleRect.size)
		CGContextTranslateCTM(UIGraphicsGetCurrentContext(), visibleRect.origin.x, visibleRect.origin.y)
		view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
		let viewImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return viewImage
	}
	
	class func imageWithView(view: UIView) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0)
		view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
		
		let img: UIImage = UIGraphicsGetImageFromCurrentImageContext()
		
		UIGraphicsEndImageContext()
		return img
	}
	
	func croppedImage(image: UIImage) -> UIImage {
		
		cropBezierPath.closePath()
		let imageSize: CGSize = image.size
		let imageRect: CGRect = CGRectMake(0, 0, imageSize.width, imageSize.height)
		UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.mainScreen().scale)
		
		cropBezierPath?.addClip()
		image.drawInRect(imageRect)
		let croppedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return croppedImage
	}
	
	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
		return self.scrollView!.subviews[0]
	}
	
	@IBAction func doneAction(sender: UIBarButtonItem) {
		
		view.viewWithTag(1234)?.removeFromSuperview()
		
		(self.delegate as! ViewController).croppedImage(self.croppedImage(DisplayImageViewController.imageWithView(self.view!)))
		
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func cancelAction(sender: UIBarButtonItem) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
}
