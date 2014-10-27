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
    @IBInspectable var fillColor:UIColor = UIColor.blackColor()
    @IBInspectable var fillBackgroundColor:UIColor = UIColor.clearColor() {
        didSet{
            backgroundLayer?.fillColor = fillBackgroundColor.CGColor
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
            pathLayer?.setAffineTransform(CGAffineTransformMakeRotation(angle))
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
            backgroundLayer?.fillColor = fillBackgroundColor.CGColor
            layer.addSublayer(backgroundLayer)
        }
        
        if pathLayer == nil {
            pathLayer = CAShapeLayer()
            pathLayer?.frame = layer.bounds
            pathLayer?.lineWidth = 0
            pathLayer?.setAffineTransform(CGAffineTransformMakeRotation(angle))
            cleanLayers()
            layer.addSublayer(pathLayer)
        }
    }
    
    private func cleanLayers() {
        pathLayer?.path = pathAtInterval(0)
        pathLayer?.fillColor = UIColor.clearColor().CGColor
    }
    
    // Color
    
    private func fillColorWithInterval(interval:NSTimeInterval) -> CGColorRef {
        let cycleInterval = CGFloat(interval.remainingAfterMultiple(animationCycleDuration))
        let halfAnimationDuration = CGFloat(animationCycleDuration / 2.0)
        
        let lowerInterval:CGFloat = halfAnimationDuration * 0.5
        let higherInterval:CGFloat = (halfAnimationDuration * 2.0) - (halfAnimationDuration * 0.5)
        
        if cycleInterval < lowerInterval {
            
            let progress:CGFloat = cycleInterval / lowerInterval
            return fillColor.colorWithAlphaComponent(progress).CGColor
            
        } else if cycleInterval > higherInterval {
            
            let progress:CGFloat = (cycleInterval - higherInterval) / lowerInterval
            return fillColor.colorWithAlphaComponent(1-progress).CGColor
            
        } else {
            return fillColor.CGColor
        }
    }
    
    // Path
    
    private func contourPath() -> CGPath {
        return UIBezierPath(ovalInRect: layer.bounds).CGPath
    }
    
    private func pathAtInterval(interval:NSTimeInterval) -> CGPathRef {
        var cycleInterval = CGFloat(interval.remainingAfterMultiple(animationCycleDuration))
        cycleInterval = LogisticCurve.calculateYWithX(cycleInterval,
            upperX: CGFloat(animationCycleDuration),
            upperY: CGFloat(animationCycleDuration))
        
        let aPath = UIBezierPath()
        
        let length = layer.bounds.width
        let halfLength = layer.bounds.width / 2.0
        let halfAnimationDuration = CGFloat(animationCycleDuration) / 2.0
        let isFirstHalfOfAnimation = cycleInterval < halfAnimationDuration
        
        aPath.moveToPoint(CGPointMake(length, halfLength))
        aPath.addArcWithCenter(CGPointMake(halfLength, halfLength),
            radius: halfLength,
            startAngle: -CGFloat(M_PI)/2.0,
            endAngle: CGFloat(M_PI)/2.0,
            clockwise: isFirstHalfOfAnimation)
        
        let x:CGFloat = length * 0.6667
        var t:CGFloat
        if isFirstHalfOfAnimation {
            t = -(2.0/halfAnimationDuration) * cycleInterval + 1
        } else {
            t = -(2.0/halfAnimationDuration) * (cycleInterval-halfAnimationDuration) + 1
        }
        let controlPointXDistance:CGFloat = halfLength + t * x
        
        aPath.addCurveToPoint(CGPointMake(halfLength, 0),
            controlPoint1: CGPointMake(controlPointXDistance, length - 0.05*length),
            controlPoint2: CGPointMake(controlPointXDistance, 0.05*length))
        aPath.closePath()
        
        return aPath.CGPath
    }
    
    // Animation
    
    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: "handleDisplayLink:")
        displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        hidden = false
    }
    
    private func stopAnimation() {
        self.displayLink?.invalidate()
        self.displayLink = nil
        cleanLayers()
    }
    
    func handleDisplayLink(displayLink:CADisplayLink) {
        if firstTimeStamp == nil {
            firstTimeStamp =  displayLink.timestamp
        }
        
        let elapse = displayLink.timestamp - firstTimeStamp!
        updatePathLayer(elapse)
    }
    
    private func updatePathLayer(interval:NSTimeInterval) {
        pathLayer?.path = pathAtInterval(interval)
        pathLayer?.fillColor = fillColorWithInterval(interval)
    }
    
    // Interface builder
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setUpLayer()
        updatePathLayer(animationCycleDuration * 0.35)
        
    }
    
}

private extension CGRect {
    func center() -> CGPoint {
        return CGPointMake(origin.x + size.width/2.0, origin.y + size.height/2.0)
    }
}

private extension Double {
    func remainingAfterMultiple(multiple:NSTimeInterval) -> NSTimeInterval {
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
