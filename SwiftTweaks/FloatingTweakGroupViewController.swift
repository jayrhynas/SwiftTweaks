//
//  FloatingTweakGroupViewController.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 4/6/16.
//  Copyright © 2016 Khan Academy. All rights reserved.
//

import UIKit


// MARK: - FloatingTweaksWindowPresenter

internal protocol FloatingTweaksWindowPresenter {
    func presentFloatingTweaksUI(forTweakGroup tweakGroup: TweakGroup, inTweakCollection tweakCollection: TweakCollection)
	func dismissFloatingTweaksUI()
}

// MARK: - FloatingTweakGroupViewController

/// A "floating" UI for a particular TweakGroup.
internal final class FloatingTweakGroupViewController: UIViewController {
    var tweakCollection: TweakCollection? {
        didSet {
            self.updateTitle()
        }
    }
    
	var tweakGroup: TweakGroup? {
		didSet {
            self.updateTitle()
			self.tableView.reloadData()
		}
	}
    
    private func updateTitle() {
        titleLabel.text = [tweakCollection?.title, tweakGroup?.title].compactMap { $0 }.joined(separator: " | ")
    }

	private let presenter: FloatingTweaksWindowPresenter
	fileprivate let tweakStore: TweakStore
	private var fullFrame: CGRect
    private var corner: Corner
    
	internal init(frame: CGRect, tweakStore: TweakStore, presenter: FloatingTweaksWindowPresenter) {
		self.tweakStore = tweakStore
		self.presenter = presenter
		self.fullFrame = frame
        self.corner = (v: .bottom, h: .right)
        
		super.init(nibName: nil, bundle: nil)

		view.frame = frame
        self.corner = self.corner(for: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    private func fullFrameOrigin(for corner: Corner) -> CGPoint {
        let margin = FloatingTweakGroupViewController.margins

        guard let window = view.window else {
            return fullFrame.origin
        }
        
        var origin = CGPoint.zero
        switch corner.h {
        case .left:  origin.x = margin
        case .right: origin.x = window.frame.width - margin - fullFrame.width
        }
        
        switch corner.v {
        case .top:    origin.y = margin
        case .bottom: origin.y = window.frame.height - margin - fullFrame.height
        }
        
        return origin
    }
    
    private func minimizedFrameOrigin(for corner: Corner) -> CGPoint {
        let margin = FloatingTweakGroupViewController.margins
        let minWidth = FloatingTweakGroupViewController.minimizedWidth
        
        guard let window = view.window else {
            return CGPoint(x: fullFrame.width - minWidth + margin * 2,
                           y: fullFrame.minY)
        }
        
        var origin = self.fullFrameOrigin(for: corner)
        switch corner.h {
        case .left:  origin.x = minWidth - fullFrame.width
        case .right: origin.x = window.frame.width - minWidth
        }
        
        return origin
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		installSubviews()
        
        self.setupKeyboardNotifications()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		tableView.flashScrollIndicators()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		layoutSubviews()
	}

    override var prefersStatusBarHidden: Bool {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController, rootVC != self {
            return rootVC.prefersStatusBarHidden
        } else {
            return super.prefersStatusBarHidden
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController, rootVC != self {
            return rootVC.preferredStatusBarStyle
        } else {
            return super.preferredStatusBarStyle
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController, rootVC != self {
            return rootVC.preferredStatusBarUpdateAnimation
        } else {
            return super.preferredStatusBarUpdateAnimation
        }
    }
    
	// MARK: Subviews

	internal static let minHeight: CGFloat = 168
	internal static let margins: CGFloat = 5
	private static let minimizedWidth: CGFloat = 30

	private static let closeButtonSize = CGSize(width: 42, height: 32)
	private static let navBarHeight: CGFloat = 32
	private static let windowCornerRadius: CGFloat = 5

	private let navBar: UIView = {
		let view = UIView()
		view.backgroundColor = AppTheme.Colors.floatingTweakGroupNavBG

		view.layer.shadowColor = AppTheme.Shadows.floatingNavShadowColor
		view.layer.shadowOpacity = AppTheme.Shadows.floatingNavShadowOpacity
		view.layer.shadowOffset = AppTheme.Shadows.floatingNavShadowOffset
		view.layer.shadowRadius = AppTheme.Shadows.floatingNavShadowRadius

		return view
	}()

	private let titleLabel: UILabel = {
		let label = UILabel()
		label.textColor = AppTheme.Colors.sectionHeaderTitleColor
		label.font = AppTheme.Fonts.sectionHeaderTitleFont
		return label
	}()

	private let closeButton: UIButton = {
		let button = UIButton()
		let buttonImage = UIImage(swiftTweaksImage: .floatingCloseButton).withRenderingMode(.alwaysTemplate)
		button.setImage(buttonImage.imageTintedWithColor(AppTheme.Colors.controlTinted), for: UIControlState())
		button.setImage(buttonImage.imageTintedWithColor(AppTheme.Colors.controlTintedPressed), for: .highlighted)
		return button
	}()

	fileprivate let tableView: UITableView = {
		let tableView = UITableView(frame: .zero, style: .plain)
		tableView.backgroundColor = .clear
		tableView.register(TweakTableCell.self, forCellReuseIdentifier: FloatingTweakGroupViewController.TweakTableViewCellIdentifer)
		tableView.contentInset = UIEdgeInsets(top: FloatingTweakGroupViewController.navBarHeight, left: 0, bottom: 0, right: 0)
		tableView.separatorColor = AppTheme.Colors.tableSeparator
		return tableView
	}()

	fileprivate let restoreButton: UIButton = {
		let button = UIButton()
		let buttonImage = UIImage(swiftTweaksImage: .floatingMinimizedArrow).withRenderingMode(.alwaysTemplate)
		button.setImage(buttonImage.imageTintedWithColor(AppTheme.Colors.controlSecondary), for: UIControlState())
		button.setImage(buttonImage.imageTintedWithColor(AppTheme.Colors.controlSecondaryPressed), for: .highlighted)
		button.isHidden = true
		return button
	}()

	private func installSubviews() {
		// Create the rounded corners and shadows
		view.layer.cornerRadius = FloatingTweakGroupViewController.windowCornerRadius
		view.layer.shadowColor = AppTheme.Shadows.floatingShadowColor
		view.layer.shadowOffset = AppTheme.Shadows.floatingShadowOffset
		view.layer.shadowRadius = AppTheme.Shadows.floatingShadowRadius
		view.layer.shadowOpacity = AppTheme.Shadows.floatingShadowOpacity

		// Set up the background
		view.backgroundColor = .white

		// The table view
		tableView.delegate = self
		tableView.dataSource = self
		view.addSubview(tableView)

		// The "fake nav bar"
		closeButton.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
		navBar.addSubview(closeButton)
		navBar.addSubview(titleLabel)
		view.addSubview(navBar)

		// The restore button
        restoreButton.addTarget(self, action: #selector(self.restore(_:)), for: .touchUpInside)
		view.addSubview(restoreButton)

		// The pan gesture recognizer
		let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.moveWindowPanGestureRecognized(_:)))
		panGestureRecognizer.delegate = self
		view.addGestureRecognizer(panGestureRecognizer)
	}

	private func layoutSubviews() {
		tableView.frame = CGRect(origin: .zero, size: view.bounds.size)

		tableView.scrollIndicatorInsets = UIEdgeInsets(
			top: tableView.contentInset.top,
			left: 0,
			bottom: 0,
			right: 0
		)

		navBar.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: FloatingTweakGroupViewController.navBarHeight))

		// Round the top two corners of the nav bar
		navBar.layer.mask = {
			let maskPath = UIBezierPath(
				roundedRect: view.bounds,
				byRoundingCorners: [.topLeft, .topRight],
				cornerRadii: CGSize(
					width: FloatingTweakGroupViewController.windowCornerRadius,
					height: FloatingTweakGroupViewController.windowCornerRadius
				)).cgPath
			let mask = CAShapeLayer()
			mask.path = maskPath
			return mask
			}()

		closeButton.frame = CGRect(origin: .zero, size: FloatingTweakGroupViewController.closeButtonSize)
		titleLabel.frame = CGRect(
			origin: CGPoint(
				x: closeButton.frame.width,
				y: 0
			),
			size: CGSize(
				width: view.bounds.width - closeButton.frame.width,
				height: navBar.bounds.height
			)
		)

		restoreButton.frame = CGRect(
			origin: .zero,
			size: CGSize(
				width: FloatingTweakGroupViewController.minimizedWidth,
				height: view.bounds.height
			)
		)
	}

    // MARK: Notifications
    
    private var prevCorner: Corner?
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: .main) { notif in
            if self.corner.v == .bottom {
                self.prevCorner = self.corner
                
                self.animateAlongsideKeyboard(notification: notif, animations: { animated in
                    self.restore(to: Corner(v: .top, h: self.corner.h), animated: !animated)
                }, completion: nil)
            } else {
                self.prevCorner = nil
            }
        }
        
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: .main) { notif in
            if let prev = self.prevCorner {
                self.animateAlongsideKeyboard(notification: notif, animations: { animated in
                    self.restore(to: prev, animated: !animated)
                }, completion: nil)
            }
        }
    }
    
    private func animateAlongsideKeyboard(notification: Notification, animations: @escaping (Bool) -> Void, completion: ((Bool) -> Void)?) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double,
              let curve    = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? UInt
        else {
            animations(false)
            completion?(true)
            return
        }
        
        let options = UIViewAnimationOptions(rawValue: curve) ?? []
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            animations(true)
        }, completion: completion)
    }
    
    
	// MARK: Actions

	@objc private func closeButtonTapped() {
		presenter.dismissFloatingTweaksUI()
	}
    
    private enum VerticalDirection {
        case top, bottom
    }
    private enum HorizontalDirection {
        case left, right
    }
    
    private typealias Corner = (v: VerticalDirection, h: HorizontalDirection)
    
	private static let gestureSpeedBreakpoint: CGFloat = 10
	private static let gesturePositionBreakpoint: CGFloat = 30

    private func corner(for frame: CGRect, velocity: CGPoint = .zero, in container: UIView? = nil) -> Corner {
        guard let container = container ?? view.window else {
            return (v: .bottom, h: .right)
        }
        
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let bias = CGPoint(x: min(max(velocity.x / 1000.0, -0.25), 0.25),
                           y: min(max(velocity.y / 1000.0, -0.25), 0.25))
        
        return (v: center.y < container.frame.height * (0.5 - bias.y) ? .top  : .bottom,
                h: center.x < container.frame.width  * (0.5 - bias.x) ? .left : .right)
    }
    
	@objc private func moveWindowPanGestureRecognized(_ gestureRecognizer: UIPanGestureRecognizer) {
		switch (gestureRecognizer.state) {
		case .began:
			gestureRecognizer.setTranslation(self.view.frame.origin, in: self.view)
            
		case .changed:
			view.frame.origin = gestureRecognizer.translation(in: self.view)
            
		case .possible, .ended, .cancelled, .failed:
            let speedBreakpoint = FloatingTweakGroupViewController.gestureSpeedBreakpoint
            let posBreakpoint   = FloatingTweakGroupViewController.gesturePositionBreakpoint
            
            let prevCorner = corner
            
            let velocity = gestureRecognizer.velocity(in: nil)
            
            corner = self.corner(for: view.frame, velocity: velocity)
            fullFrame.origin = self.fullFrameOrigin(for: corner)

            var gestureIsMovingToEdge: Bool {
                guard abs(velocity.x) > abs(velocity.y) else {
                    return false
                }
                
                let vel = velocity.x
                switch corner.h {
                case .left:  return vel < -speedBreakpoint
                case .right: return vel > speedBreakpoint
                }
            }

            var viewIsKindaNearTheEdge: Bool {
                switch corner.h {
                case .left:  return view.frame.maxX < (fullFrame.maxX - posBreakpoint)
                case .right: return view.frame.minX > (fullFrame.minX + posBreakpoint)
                }
            }
            
			if corner == prevCorner && gestureIsMovingToEdge && viewIsKindaNearTheEdge {
                minimize(to: corner)
			} else {
				restore()
			}
		}
	}

	private static let minimizeAnimationDuration: Double = 0.3
	private static let minimizeAnimationDamping: CGFloat = 0.8

    private func minimize(to corner: Corner) {
		// TODO map the continuous gesture's velocity into the animation.
		self.restoreButton.alpha = 0
		self.restoreButton.isHidden = false

        switch corner.h {
        case .left:
            restoreButton.imageView?.transform = .init(scaleX: -1.0, y: 1.0)
            restoreButton.frame.origin.x = view.frame.width - restoreButton.frame.width
            
        case .right:
            restoreButton.imageView?.transform = .identity
            restoreButton.frame.origin.x = 0
        }
        
		UIView.animate(
			withDuration: FloatingTweakGroupViewController.minimizeAnimationDuration,
			delay: 0,
			usingSpringWithDamping: FloatingTweakGroupViewController.minimizeAnimationDamping,
			initialSpringVelocity: 0,
			options: .beginFromCurrentState,
			animations: {
				self.view.frame.origin = self.minimizedFrameOrigin(for: corner)
				self.tableView.alpha = 0
				self.navBar.alpha = 0
				self.restoreButton.alpha = 1
			},
			completion: nil
		)
	}

    private func restore(to corner: Corner, animated: Bool = true) {
        self.corner = corner
        self.fullFrame.origin = self.fullFrameOrigin(for: corner)
        self.restore(animated: animated)
    }
    
    @objc private func restore(_ sender: UIButton) {
        self.restore()
    }
    
    private func restore(animated: Bool = true) {
		// TODO map the continuous gesture's velocity into the animation

        let animations = {
            self.view.frame.origin = self.fullFrame.origin
            self.tableView.alpha = 1
            self.navBar.alpha = 1
            self.restoreButton.alpha = 0
        }
        
        let completion = { (finished: Bool) in
            self.restoreButton.isHidden = true
        }
        
        if animated {
            UIView.animate(
                withDuration: FloatingTweakGroupViewController.minimizeAnimationDuration,
                delay: 0,
                usingSpringWithDamping: FloatingTweakGroupViewController.minimizeAnimationDamping,
                initialSpringVelocity: 0,
                options: .beginFromCurrentState,
                animations: animations,
                completion: completion
            )
        } else {
            animations()
            completion(true)
        }
	}
}

extension FloatingTweakGroupViewController: UIGestureRecognizerDelegate {
	@objc func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let hitView = gestureRecognizer.view?.hitTest(gestureRecognizer.location(in: gestureRecognizer.view), with: nil) else {
			return true
		}

		// We don't want to move the window if you're trying to drag a slider or a switch!
		// But if you're dragging on the restore button, that's what we do want!
		let gestureIsNotOnAControl = !hitView.isKind(of: UIControl.self)
		let gestureIsOnTheRestoreButton = hitView == restoreButton

		return gestureIsNotOnAControl || gestureIsOnTheRestoreButton
	}
}

// MARK: Table View

extension FloatingTweakGroupViewController: UITableViewDelegate {
	@objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let tweak = tweakAtIndexPath(indexPath) else { return }
		switch tweak.tweakViewDataType {
		case .uiColor:
			let alert = UIAlertController(title: "Can't edit colors here.", message: "Sorry, haven't built out the floating UI for it yet!", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
			present(alert, animated: true, completion: nil)
        case .stringList:
            if let alert = self.stringListAlert(for: tweak) {
                present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Can't edit string-options with more than 10 options here.", message: "Sorry, haven't built out the floating UI for it yet!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
		case .boolean, .integer, .cgFloat, .double:
			break
		}
	}
    
    private func stringListAlert(for tweak: AnyTweak) -> UIAlertController? {
        let viewData = self.tweakStore.currentViewDataForTweak(tweak)
        guard case let .stringList(value, defaultValue, options) = viewData, options.count <= 10 else {
            return nil
        }
        
        let alert = UIAlertController(title: tweak.tweakName, message: nil, preferredStyle: .alert)
        
        for option in options {
            alert.addAction(UIAlertAction(title: option.value, style: .default, handler: { action in
                self.tweakStore.setValue(.stringList(value: option, defaultValue: defaultValue, options: options), forTweak: tweak)
                self.tableView.reloadData()
            }))
        }
        
        return alert
    }
}

extension FloatingTweakGroupViewController: UITableViewDataSource {
	fileprivate static let TweakTableViewCellIdentifer = "TweakTableViewCellIdentifer"

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tweakGroup?.tweaks.count ?? 0
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: FloatingTweakGroupViewController.TweakTableViewCellIdentifer, for: indexPath) as! TweakTableCell

		let tweak = tweakAtIndexPath(indexPath)!

		cell.textLabel?.text = tweak.tweakName
		cell.isInFloatingTweakGroupWindow = true
		cell.viewData = tweakStore.currentViewDataForTweak(tweak)
		cell.delegate = self
		cell.backgroundColor = .clear
		cell.contentView.backgroundColor = .clear

		return cell
	}

	fileprivate func tweakAtIndexPath(_ indexPath: IndexPath) -> AnyTweak? {
		return tweakGroup?.sortedTweaks[(indexPath as NSIndexPath).row]
	}
}

// MARK: TweakTableCellDelegate

extension FloatingTweakGroupViewController: TweakTableCellDelegate {
	func tweakCellDidChangeCurrentValue(_ tweakCell: TweakTableCell) {
		if
			let indexPath = tableView.indexPath(for: tweakCell),
			let viewData = tweakCell.viewData,
			let tweak = tweakAtIndexPath(indexPath)
		{
			tweakStore.setValue(viewData, forTweak: tweak)
		}
	}
}
