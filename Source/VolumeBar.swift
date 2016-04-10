//
//  VolumeBar.swift
//
//  Created by Sachin Patel on 3/6/16.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016-Present Sachin Patel (http://gizmosachin.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import AudioToolbox
import MediaPlayer

/// Conforming types can receive notifications on when the VolumeBar shows and hides.
public protocol VolumeDelegate {
	/// Notifies the delegate that a VolumeBar is about to be shown.
	///
	/// - parameter volumeBar: The volume bar.
	func volumeBarWillShow(volumeBar: VolumeBar)
	
	/// Notifies the delegate that a VolumeBar was hidden.
	///
	/// - parameter volumeBar: The volume bar.
	func volumeBarDidHide(volumeBar: VolumeBar)
}

/// The main VolumeBar class.
public class VolumeBar: NSObject {
	/// A set of animation styles.
	public enum AnimationStyle {
		/// Slide in and out of view from the top of the screen.
		case Slide
		
		/// Fade in and out.
		case Fade
	}
	
	/// The shared instance of `VolumeBar`. This should be used in most cases.
	static let sharedInstance = VolumeBar()
	
	/// The delegate must adopt the `VolumeDelegate` protocol.
	public var delegate: VolumeDelegate?
	
	// MARK: Animation
	
	/// The animation style to be applied to this `VolumeBar`.
	public var animationStyle: AnimationStyle = .Slide
	
	/// The animation duration to be applied to this `VolumeBar` when being presented or hidden.
	public var animationDuration: NSTimeInterval = 0.3
	
	/// The minimum duration to be shown on screen.
	///
	/// Subsequent volume button presses that occur while this `VolumeBar` is already on screen will extend the on screen duration by this value.
	public var minimumVisibleDuration: NSTimeInterval = 1.5
	
	// MARK: Layout
	
	/// The number of segments that the `VolumeBar` should be broken into. 
	///
	/// Use this value with `interitemSpacing` to get a segmented appearance rather than a continuous bar.
	public var segmentCount: Int = 16
	
	/// The height of the internal bar.
	///
	/// See `updateHeight()`. The height of the `VolumeBar` is set as follows:
	/// ### In portrait mode:
	/// - If `statusBarHidden` = `false`: 20
	/// - If `statusBarHidden` = `true` : `barHeight` + 6
	///
	/// ### In landscape mode:
	/// - If the `rootViewController` of the key window is a `UINavigationController`: the height of the navigation bar
	/// - Otherwise: `barHeight` + 6
	public var barHeight: CGFloat = 2.0 {
		didSet {
			updateHeight()
		}
	}
	
	/// The spacing between segments of the bar.
	///
	/// Set this value to greater than 0 to get a segmented appearance rather than a continuous bar.
	public var interitemSpacing: CGFloat = 0 {
		didSet {
			volumeViewController.view.setNeedsLayout()
		}
	}
	
	/// A Boolean value indicating whether the status bar on the current view controller is hidden.
	///
	/// Update this value on each view controller where `prefersStatusBarHidden()` is overridden.
	/// Not updating this value appropriately will result in presentation glitches for `VolumeBar`.
	public var statusBarHidden: Bool = false{
		didSet {
			updateHeight()
		}
	}
	
	/// The status bar style of the current view controller.
	///
	/// Update this value on each view controller where `preferredStatusBarStyle()` is overridden.
	/// Not updating this value appropriately will result in presentation glitches for `VolumeBar`.
	public var statusBarStyle: UIStatusBarStyle = .Default
	
	// MARK: Appearance
	
	/// The tint color of the `VolumeBar`.
	///
	/// This value controls the tint color of the internal bar that reflects the volume level.
	public var tintColor: UIColor = UIColor.blackColor() {
		didSet {
			volumeViewController.view.tintColor = tintColor
			volumeViewController.refresh()
		}
	}
	
	/// The background color of the `VolumeBar`.
	///
	/// This value controls the background color of the `VolumeBar`.
	public var backgroundColor: UIColor = UIColor.whiteColor() {
		didSet {
			volumeViewController.view.backgroundColor = backgroundColor
		}
	}
	
	/// The track color of the `VolumeBar`.
	///
	/// This value controls the background color of the track.
	public var trackTintColor: UIColor = UIColor.blackColor().colorWithAlphaComponent(0.1) {
		didSet {
			volumeViewController.trackView.backgroundColor = trackTintColor
		}
	}
	
	// MARK: Internal
	
	/// A Boolean value that reflects whether the `VolumeBar` is currently observing system volume changes.
	private var observingVolumeChanges: Bool = false
	
	/// A `UIWindow` that is inserted above the system status bar to show the volume indicator.
	private let volumeWindow: UIWindow = UIWindow()
	
	/// A timer that controls when the `VolumeBar` automatically hides.
	///
	/// Each time a volume button is pressed, the timer is invalidated and set again with duration `minimumVisibleDuration`.
	private var hideTimer: NSTimer?
	
	/// A Boolean value that reflects whether the status bar should actually be hidden.
	///
	/// On iPhone, the status bar is always hidden when the device is in landscape mode,
    /// regardless of the return value of `prefersStatusBarHidden()` for the view controller.
	private var statusBarActuallyHidden: Bool {
		get {
			let orientation = UIApplication.sharedApplication().statusBarOrientation
			let phoneLandscape = UI_USER_INTERFACE_IDIOM() == .Phone && (orientation == .LandscapeLeft || orientation == .LandscapeRight)
			return phoneLandscape ? true : statusBarHidden
		}
	}

	/// The internal view controller used to show the current system volume.
	private var volumeViewController: VolumeBarViewController = VolumeBarViewController()
	
	/// Pressing either volume button changes volume by 0.0625 (experimentally determined constant).
	static let volumeStep = 0.0625
	
	// MARK: - Init
	
	/// Creates a new instance of `VolumeBar`.
	private override init() {
		super.init()
		
		// Set up the internal view controller
		volumeViewController.volumeBar = self
		volumeViewController.view.frame = volumeWindow.bounds
		
		// Update the window height and configure the window
		updateHeight()
		volumeWindow.hidden = true
		volumeWindow.backgroundColor = nil
		volumeWindow.rootViewController = volumeViewController
		volumeWindow.windowLevel = UIWindowLevelStatusBar + 1
	}
	
	// MARK: - Automatic Presentation
	
	/// Start observing changes in volume.
	///
	/// Once this method is called, the `VolumeBar` will automatically show when volume buttons
	/// are pressed as long as the application is active and `stop()` hasn't been called.
	public func start() {
		if !observingVolumeChanges {
			observingVolumeChanges = true
			
			// Initialize the audio session
			do {
				try AVAudioSession.sharedInstance().setActive(true)
			} catch {
				print("VolumeBar: Initializing audio session failed.")
			}
			
			// Observe volume changes
			AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.Old, .New], context: nil)
			
			// Observe when application resumes from background
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
			
			// Observe device rotation
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VolumeBar.updateHeight), name: UIDeviceOrientationDidChangeNotification, object: nil)
		}
	}
	
	/// Stop observing changes in volume.
	///
	/// Once this method is called, the `VolumeBar` will no longer show when volume buttons
	/// are pressed. Calling this method has no effect if `start()` hasn't previously been called.
	public func stop() {
		if observingVolumeChanges {
			// Stop observing volume changes
			AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
			
			// Stop observing application changes and device rotation
			NSNotificationCenter.defaultCenter().removeObserver(self)
		}
	}
	
	/// Updates the height of the `VolumeBar` according to the `barHeight` and other factors.
	///
	/// See documentation for `barHeight` for details.
	internal func updateHeight() {
		guard let mainWindow = UIApplication.sharedApplication().keyWindow else { return }
		
		// Default to height of 20
		var height = CGFloat(20)
		
		// If iPhone in landscape mode, the root view controller of the
		// primary window is a navigation controller, and the status bar is not
		// hidden, set the height equal to the height of the navigation bar.
		let orientation = UIApplication.sharedApplication().statusBarOrientation
		let phoneLandscape = UI_USER_INTERFACE_IDIOM() == .Phone && (orientation == .LandscapeLeft || orientation == .LandscapeRight)
		
		if statusBarHidden {
			height = barHeight + 6
		} else if let navigationController = mainWindow.rootViewController as? UINavigationController where phoneLandscape {
			height = navigationController.navigationBar.frame.size.height
		}
		
		// Set the window frame, update status bar appearance
		volumeWindow.frame = CGRectMake(0, 0, mainWindow.bounds.width, height)
		volumeViewController.view.setNeedsLayout()
		volumeViewController.setNeedsStatusBarAppearanceUpdate()
	}
	
	// MARK: - Presentation
	
	/// Shows the `VolumeBar` at the top of the screen.
	///
	/// The presentation of the `VolumeBar` can be customized by setting the `animationStyle`,
	/// `animationDuration`, and `minimumVisibleDuration` properties of the `VolumeBar`.
	public func show() {
		// Only show when the application is active
		if UIApplication.sharedApplication().applicationState != .Active {
			return
		}
		
		// Update the internal view controller before presenting
		volumeViewController.refresh()
		
		var hideDuration = minimumVisibleDuration
		
		// Only show the `volumeWindow` if not already showing
		if volumeWindow.hidden {
			// Show the window
			volumeWindow.makeKeyAndVisible()
			volumeWindow.hidden = false
			
			// Call the delegate method
			delegate?.volumeBarWillShow(self)
			
			// Set up for animation
			switch animationStyle {
			case .Fade:
				volumeViewController.view.alpha = 0.0
			case .Slide:
				volumeViewController.view.alpha = 0.0
				volumeViewController.view.transform = CGAffineTransformMakeTranslation(0, -volumeWindow.bounds.height)
			}
			
			// If style is `.Fade`, show instantly
			let duration = animationStyle == .Fade ? 0.0 : animationDuration
			
			// Add the duration of the animation to `minimumVisibleDuration`
			hideDuration += duration
			
			// Perform animation
			UIView.animateWithDuration(duration, delay: 0, options: [.BeginFromCurrentState], animations: { 
				switch self.animationStyle {
				case .Fade:
					self.volumeViewController.view.alpha = 1.0
				case .Slide:
					self.volumeViewController.view.alpha = 1.0
					self.volumeViewController.view.transform = CGAffineTransformIdentity
				}
			}, completion: nil)
		}
		
		// Invalidate the timer and extend the on-screen duration.
		hideTimer?.invalidate()
		hideTimer = NSTimer.scheduledTimerWithTimeInterval(hideDuration, target: self, selector: #selector(VolumeBar.hide), userInfo: nil, repeats: false)
	}
	
	/// Hides the `VolumeBar`.
	///
	/// The presentation of the `VolumeBar` can be customized by setting the `animationStyle`,
	/// `animationDuration`, and `minimumVisibleDuration` properties of the `VolumeBar`.
	public func hide() {
		UIView.animateWithDuration(animationDuration, delay: 0, options: [.BeginFromCurrentState], animations: {
			switch self.animationStyle {
			case .Fade:
				self.volumeViewController.view.alpha = 0.0
			case .Slide:
				self.volumeViewController.view.alpha = 0.0
				self.volumeViewController.view.transform = CGAffineTransformMakeTranslation(0, -self.volumeWindow.bounds.height)
			}
		}) { (completed) in
			self.volumeWindow.hidden = true
			self.delegate?.volumeBarDidHide(self)
			switch self.animationStyle {
			case .Fade:
				self.volumeViewController.view.alpha = 1.0
			case .Slide:
				self.volumeViewController.view.alpha = 1.0
				self.volumeViewController.view.transform = CGAffineTransformIdentity
			}
		}
	}
	
	// MARK: - Observer callbacks
	
	/// Observe changes in volume.
	///
	/// This method is called when the user presses either of the volume buttons.
	override public func observeValueForKeyPath(keyPath: String?, ofObject _object: AnyObject?, change _change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		// Exit early if the object isn't an `AVAudioSession`.
		guard let _ = _object as? AVAudioSession else { return }
		
		show()
	}
	
	
	/// Observe when the application becomes active.
	public func applicationDidBecomeActive(notification: NSNotification) {
		
		// Restart session after entering from the background
		if observingVolumeChanges {
			observingVolumeChanges = false
			start()
		}
	}
}

// MARK: -
/// The internal view controller used by `VolumeBar`.
private class VolumeBarViewController: UIViewController {
	/// A reference to the associated `VolumeBar` instance.
	///
	/// Used to retrieve appearance properties from the `VolumeBar`.
	private var volumeBar: VolumeBar? {
		didSet {
			refresh()
		}
	}
	
	// MARK: Views
	private var trackView: UIView = UIView()
	private var segmentViews: [UIView] = [UIView]()
	
	// MARK: - Init
	private override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
		// Appearance defaults
		view.tintColor = UIColor.blackColor()
		view.backgroundColor = UIColor.whiteColor()
		
		trackView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.1)
		view.addSubview(trackView)
	}
	
	private required init?(coder aDecoder: NSCoder) {
		fatalError("Please use volume.sharedInstance instead of instantiating VolumeBarViewController directly.")
	}
	
	// MARK: - View lifecycle
	
	/// Called when the view is loaded.
	private override func viewDidLoad() {
		super.viewDidLoad()
		
		// A non-hidden MPVolumeView is needed to prevent the system volume HUD from showing.
		let volumeView = MPVolumeView()
		volumeView.clipsToBounds = true
		volumeView.frame = CGRect.zero
		UIApplication.sharedApplication().windows.first?.addSubview(volumeView)
	}
	
	/// Performs internal layout.
	private override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		guard let bar = volumeBar else { return }
		let windowHeight = bar.volumeWindow.bounds.height
		let horizontalMargin = bar.interitemSpacing > 0 ? bar.interitemSpacing : 5
		let edgeInsets = UIEdgeInsets(top: (windowHeight - bar.barHeight) / 2, left: horizontalMargin, bottom: (windowHeight - bar.barHeight) / 2, right: horizontalMargin)
		
		// Calculate size of a segment based on view width.
		let effectiveWidth = view.bounds.width - edgeInsets.left - edgeInsets.right
		let segmentHeight = view.bounds.height - edgeInsets.top - edgeInsets.bottom
		let segmentWidth = (effectiveWidth - CGFloat(bar.segmentCount) * bar.interitemSpacing) / CGFloat(bar.segmentCount)
		
		// Layout track view
		trackView.frame = UIEdgeInsetsInsetRect(view.frame, edgeInsets)
		
		// Layout segments
		for (index, segment) in segmentViews.enumerate() {
			let segmentX = edgeInsets.left + CGFloat(index) * bar.interitemSpacing + (segmentWidth * CGFloat(index))
			segment.frame = CGRect(x: segmentX, y: edgeInsets.top, width: segmentWidth, height: segmentHeight)
		}
	}
	
	/// Returns the `statusBarStyle` property of the `VolumeBar`.
	private override func preferredStatusBarStyle() -> UIStatusBarStyle {
		guard let bar = volumeBar else { return .Default }
		return bar.statusBarStyle
	}
	
	/// Returns the `statusBarHidden` property of the `VolumeBar`.
	private override func prefersStatusBarHidden() -> Bool {
		guard let bar = volumeBar else { return false }
		return bar.statusBarActuallyHidden
	}
	
	// MARK: -
	
	/// Updates the appearance and alpha of segments.
	///
	/// See the `segmentCount` propetitrty of `VolumeBar`.
	private func refresh() {
		guard let bar = volumeBar else { return }
		
		// Update segments if necessary
		let tintColorChanged = segmentViews.count > 0 && view.tintColor.isEqual(segmentViews[0].backgroundColor)
		if segmentViews.count != bar.segmentCount || tintColorChanged {
			// Remove existing segments from view
			for segment in segmentViews {
				segment.removeFromSuperview()
			}
			
			segmentViews.removeAll()
			
			// Initialize new segments
			for _ in 0..<bar.segmentCount {
				let segment = UIView()
				segment.backgroundColor = view.tintColor
				view.addSubview(segment)
				segmentViews.append(segment)
			}
		}
		
		// Update status bar appearance
		setNeedsStatusBarAppearanceUpdate()
		
		// Get the current volume
		let volume = AVAudioSession.sharedInstance().outputVolume
		
		// Determine the current volume step and max number of steps.
		let currentStep = floor(volume / Float(VolumeBar.volumeStep))
		let stepCount = Float(1.0 / VolumeBar.volumeStep)
		
		// Determine the number of segments to be shown as active.
		let activeSegmentCount = (currentStep / stepCount) * Float(bar.segmentCount)
		
		// Iterate over segments.
		for (index, segment) in segmentViews.enumerate() {
			// Set tint color.
			segment.backgroundColor = view.tintColor
			
			if Float(index) < activeSegmentCount {
				// Show segment as active.
				segment.alpha = 1.0
				
				// Set the last segment to be partially filled.
				if Float(index) == floor(activeSegmentCount) {
					segment.alpha = CGFloat(activeSegmentCount - floor(activeSegmentCount))
				}
			} else {
				// Hide segment.
				segment.alpha = 0.0
			}
		}
	}
}
