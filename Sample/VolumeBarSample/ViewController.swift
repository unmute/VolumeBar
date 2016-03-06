//
//  ViewController.swift
//  VolumeBar
//
//  Created by Sachin on 3/5/16.
//  Copyright © 2016 Sachin Patel. All rights reserved.
//

import UIKit
import AudioToolbox
import MediaPlayer

class ViewController: UIViewController, UIScrollViewDelegate {
	let titleLabel: UILabel
	let subtitleLabel: UILabel
	
	let segmentedControl: UISegmentedControl
	let imageView: UIImageView

	var statusBarHidden: Bool
	
	struct Style {
		var name: String
		var closure: () -> ()
	}
	var styles: [Style]
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		titleLabel = UILabel()
		subtitleLabel = UILabel()
		segmentedControl = UISegmentedControl()
		imageView = UIImageView(image: UIImage(named: "BackgroundImage"))
		statusBarHidden = false
		styles = [Style]()
		
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func commonInit() {
		imageView.contentMode = .ScaleAspectFill
		view.addSubview(imageView)
		
		titleLabel.text = "VolumeBar"
		titleLabel.font = UIFont.systemFontOfSize(40, weight: UIFontWeightMedium)
		titleLabel.textAlignment = .Center
		view.addSubview(titleLabel)
		
		subtitleLabel.text = "Press either volume button to view."
		subtitleLabel.font = UIFont.systemFontOfSize(17, weight: UIFontWeightRegular)
		subtitleLabel.numberOfLines = 2
		subtitleLabel.textAlignment = .Center
		view.addSubview(subtitleLabel)
		
		configureStyles()
		segmentedControl.addTarget(self, action: "update", forControlEvents: .ValueChanged)
		segmentedControl.selectedSegmentIndex = 0
		view.addSubview(segmentedControl)
		
		update()
	}
	
	func configureStyles() {
		// Default style
		styles.append(Style(name: "Default", closure: {
			self.titleLabel.textColor = UIColor.blackColor()
			self.subtitleLabel.textColor = UIColor.blackColor()
			self.imageView.alpha = 0
			self.segmentedControl.tintColor = self.view.tintColor
			
			self.statusBarHidden = false
			self.setNeedsStatusBarAppearanceUpdate()
			
			VolumeBar.sharedInstance.animationStyle = .Slide
			VolumeBar.sharedInstance.barHeight = 2
			VolumeBar.sharedInstance.segmentCount = 16
			VolumeBar.sharedInstance.interitemSpacing = 0
			VolumeBar.sharedInstance.tintColor = UIColor.blackColor()
			VolumeBar.sharedInstance.backgroundColor = UIColor.whiteColor()
			VolumeBar.sharedInstance.trackTintColor = UIColor.blackColor().colorWithAlphaComponent(0.1)
			VolumeBar.sharedInstance.statusBarHidden = false
		}))
		
		// Segmented style
		styles.append(Style(name: "Segmented", closure: {
			self.titleLabel.textColor = UIColor.whiteColor()
			self.subtitleLabel.textColor = UIColor.whiteColor()
			self.imageView.alpha = 1
			self.segmentedControl.tintColor = UIColor.whiteColor()
			
			self.statusBarHidden = true
			self.setNeedsStatusBarAppearanceUpdate()
			
			VolumeBar.sharedInstance.animationStyle = .Fade
			VolumeBar.sharedInstance.barHeight = 5
			VolumeBar.sharedInstance.segmentCount = 8
			VolumeBar.sharedInstance.interitemSpacing = 3
			VolumeBar.sharedInstance.tintColor = UIColor.whiteColor()
			VolumeBar.sharedInstance.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
			VolumeBar.sharedInstance.trackTintColor = UIColor.clearColor()
			VolumeBar.sharedInstance.statusBarHidden = true
		}))
		
		// Add a segment for each style
		for (index, style) in styles.enumerate() {
			segmentedControl.insertSegmentWithTitle(style.name, atIndex: index, animated: false)
		}
	}

	// MARK: -
	func update() {
		let selected = segmentedControl.selectedSegmentIndex
		if selected < 0 || selected >= styles.count { return }
		styles[segmentedControl.selectedSegmentIndex].closure()
	}
	
	// MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Don't interrupt user audio
		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
		
		// Start VolumeBar
		VolumeBar.sharedInstance.start()
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let labelMargin = CGFloat(20)
		let controlMargin = CGFloat(20)
		
		let titleHeight = CGFloat(40)
		let subtitleHeight = CGFloat(30)
		titleLabel.frame = CGRect(x: labelMargin, y: (view.bounds.height - titleHeight) / 2, width: view.bounds.width - labelMargin * 2, height: titleHeight)
		subtitleLabel.frame = CGRect(x: labelMargin, y: (view.bounds.height - titleHeight) / 2 + titleHeight + 10, width: view.bounds.width - labelMargin * 2, height: subtitleHeight)
		segmentedControl.frame = CGRect(x: controlMargin, y: view.bounds.height - controlMargin - 30, width: view.bounds.width - controlMargin * 2, height: 30)
		imageView.frame = view.bounds
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func prefersStatusBarHidden() -> Bool {
		return statusBarHidden
	}
}
