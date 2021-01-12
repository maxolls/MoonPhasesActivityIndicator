//
//  BallActivityIndicator.swift
//  Animations
//
//  Created by Maxime Ollivier on 10/26/14.
//  Copyright (c) 2014 MaximeOllivier. All rights reserved.
//

import UIKit

@IBDesignable
class MoonActivityIndicator: UIView {
    
    //Parameters
    @IBInspectable var animationCycleDuration:Double = 2.0
    @IBInspectable var fillColor:UIColor = UIColor.black
    @IBInspectable var fillBackgroundColor:UIColor = UIColor.clear {
        didSet{
            backgroundLayer?.fillColor = fillBackgroundColor.cgColor
        }
    }
    @IBInspectable var animating:Bool = false {
        didSet(oldValue) {
            if oldValue != animating {
                if animating {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
        }
    }
    @IBInspectable var angle:CGFloat = 0.0 {
        didSet {
            pathLayer?.setAffineTransform(CGAffineTransform(rotationAngle: angle))
        }
    }
    
    
    //Layers
    private var pathLayer:CAShapeLayer?
    private var backgroundLayer:CAShapeLayer?
    
    //Display
    private var displayLink:CADisplayLink?
    private var firstTimeStamp:CFTimeInterval?
    
    
    override func didMoveToSuperview() {
        setUpLayer()
    }
    
    private func setUpLayer() {
        if backgroundLayer == nil {
            backgroundLayer = CAShapeLayer()
            backgroundLayer?.frame = layer.bounds
            backgroundLayer?.path = contourPath()
            backgroundLayer?.fillColor = fillBackgroundColor.cgColor
            layer.addSublayer(backgroundLayer!)
        }
        
        if pathLayer == nil {
            pathLayer = CAShapeLayer()
            pathLayer?.frame = layer.bounds
            pathLayer?.lineWidth = 0
            pathLayer?.setAffineTransform(CGAffineTransform(rotationAngle: angle))
            cleanLayers()
            layer.addSublayer(pathLayer!)
        }
    }
    
    private func cleanLayers() {
        pathLayer?.path = pathAtInterval(interval: 0)
        pathLayer?.fillColor = UIColor.clear.cgColor
    }
    
    // Color
    
    private func fillColorWithInterval(interval:TimeInterval) -> CGColor {
        let cycleInterval = CGFloat(interval.remainingAfterMultiple(multiple: animationCycleDuration))
        let halfAnimationDuration = CGFloat(animationCycleDuration / 2.0)
        
        let lowerInterval:CGFloat = halfAnimationDuration * 0.5
        let higherInterval:CGFloat = (halfAnimationDuration * 2.0) - (halfAnimationDuration * 0.5)
        
        if cycleInterval < lowerInterval {
            
            let progress:CGFloat = cycleInterval / lowerInterval
            return fillColor.withAlphaComponent(progress).cgColor
            
        } else if cycleInterval > higherInterval {
            
            let progress:CGFloat = (cycleInterval - higherInterval) / lowerInterval
            return fillColor.withAlphaComponent(1-progress).cgColor
            
        } else {
            return fillColor.cgColor
        }
    }
    
    // Path
    
    private func contourPath() -> CGPath {
        return UIBezierPath(ovalIn: layer.bounds).cgPath
    }
    
    private func pathAtInterval(interval:TimeInterval) -> CGPath {
        var cycleInterval = CGFloat(interval.remainingAfterMultiple(multiple: animationCycleDuration))
        cycleInterval = LogisticCurve.calculateYWithX(x: cycleInterval,
            upperX: CGFloat(animationCycleDuration),
            upperY: CGFloat(animationCycleDuration))
        
        let aPath = UIBezierPath()
        
        let length = layer.bounds.width
        let halfLength = layer.bounds.width / 2.0
        let halfAnimationDuration = CGFloat(animationCycleDuration) / 2.0
        let isFirstHalfOfAnimation = cycleInterval < halfAnimationDuration
        
        aPath.move(to: CGPoint(x: length, y: halfLength))
        aPath.addArc(withCenter: CGPoint(x: halfLength,y: halfLength),
            radius: halfLength,
            startAngle: -CGFloat(Double.pi)/2.0,
            endAngle: CGFloat(Double.pi)/2.0,
            clockwise: isFirstHalfOfAnimation)
        
        let x:CGFloat = length * 0.6667
        var t:CGFloat
        if isFirstHalfOfAnimation {
            t = -(2.0/halfAnimationDuration) * cycleInterval + 1
        } else {
            t = -(2.0/halfAnimationDuration) * (cycleInterval-halfAnimationDuration) + 1
        }
        let controlPointXDistance:CGFloat = halfLength + t * x
        
        aPath.addCurve(to: CGPoint(x: halfLength, y: 0),
                       controlPoint1: CGPoint(x: controlPointXDistance, y: length - 0.05*length),
                       controlPoint2: CGPoint(x: controlPointXDistance, y: 0.05*length))
        aPath.close()
        
        return aPath.cgPath
    }
    
    // Animation
    
    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(displayLink:)))
        displayLink?.add(to: RunLoop.current, forMode: .default)
        isHidden = false
    }
    
    private func stopAnimation() {
        self.displayLink?.invalidate()
        self.displayLink = nil
        cleanLayers()
    }
    
    @objc func handleDisplayLink(displayLink: CADisplayLink) {
        if firstTimeStamp == nil {
            firstTimeStamp =  displayLink.timestamp
        }
        
        let elapse = displayLink.timestamp - firstTimeStamp!
        updatePathLayer(interval: elapse)
    }
    
    private func updatePathLayer(interval: TimeInterval) {
        pathLayer?.path = pathAtInterval(interval: interval)
        pathLayer?.fillColor = fillColorWithInterval(interval: interval)
    }
    
    // Interface builder
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setUpLayer()
        updatePathLayer(interval: animationCycleDuration * 0.35)
        
    }
    
}

private extension CGRect {
    func center() -> CGPoint {
        return CGPoint(x:origin.x + size.width/2.0, y: origin.y + size.height/2.0)
    }
}

private extension Double {
    func remainingAfterMultiple(multiple:TimeInterval) -> TimeInterval {
        return self - multiple * floor(self/multiple)
    }
}

private class LogisticCurve {
    
    class func calculateYWithX(x:CGFloat,lowerX:CGFloat = 0, upperX:CGFloat,lowerY:CGFloat = 0, upperY:CGFloat) -> CGFloat {
        // X scaling
        let b = -6.0 * (upperX+lowerX) / (upperX-lowerX)
        let m = (6.0-b)/upperX
        let scaledX = m * x + b
        
        // Logistics
        let y = 1.0 / (1.0 + pow(CGFloat(M_E), -scaledX))
        
        // Y scaling
        let yScaled = (upperY - lowerY) * y + lowerY
        
        return yScaled
    }
}
