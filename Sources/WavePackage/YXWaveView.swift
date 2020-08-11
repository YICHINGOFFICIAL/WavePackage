//
//  YXWaveView.swift
//  YXWaveView
//
//  Created by YourtionGuo on 8/26/16.
//  Copyright © 2016 Yourtion. All rights reserved.
//

import UIKit

open class YXWaveView: UIView {
    
    /// wave curvature (default: 1.5) 影響波長，值越大波長越小
    open var waveCurvature: CGFloat = 1.5
    /// wave speed (default: 0.6)
    open var waveSpeed: CGFloat = 0.6
    /// wave height (default: 5) 波峰跟波谷的距離
    open var waveHeight: CGFloat = 10
    /// 水平線高度 0~1
    open var waveBaseHeightRatio: CGFloat = 0.5{
        didSet {
            if waveBaseHeightRatio > 1{
                waveBaseHeightRatio = 1
            }else if waveBaseHeightRatio < 0{
                waveBaseHeightRatio = 0
            }
            baseOffset = (waveBaseHeightRatio - _waveBaseHeightRatio) / 400
        }
    }
    
    /// wave timmer
    fileprivate var timer: CADisplayLink?
    /// wave
    fileprivate var waveLayerArray :[WaveLayer] = []
    /// wave height offset
    fileprivate var offset :CGFloat = 0
    /// wave base height offset
    fileprivate var baseOffset :CGFloat = 0

    fileprivate var _waveBaseHeightRatio: CGFloat = 0
    fileprivate var _waveCurvature: CGFloat = 0
    fileprivate var _waveSpeed: CGFloat = 0
    fileprivate var _waveHeight: CGFloat = 0
    fileprivate var _starting: Bool = false
    fileprivate var _stoping: Bool = false

    /**
     Init view

     - parameter frame: view frame

     - returns: view
    */
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }

    /**
     Init view with wave color

     - parameter frame: view frame
     - parameter color: real wave color

     - returns: view
    */
    public convenience init(frame: CGRect,
                            waveNumber: Int = 3,
                            waveColor: UIColor = UIColor.white.withAlphaComponent(0.5),
                            waveCurvature: CGFloat = 1.5,
                            waveSpeed: CGFloat = 0.6,
                            waveHeight: CGFloat = 10,
                            initWaveBaseHeightRatio: CGFloat = 0,
                            targetWaveBaseHeightRatio: CGFloat = 0.5) {
        self.init(frame: frame)
        
        self.waveCurvature = waveCurvature
        self.waveSpeed = waveSpeed
        self.waveHeight = waveHeight
        self._waveBaseHeightRatio = initWaveBaseHeightRatio
        self.waveBaseHeightRatio = targetWaveBaseHeightRatio
        
        var frame = self.bounds
        frame.origin.y = frame.size.height
        frame.size.height = 0

        for _ in 0..<waveNumber{
            let waveLayer = WaveLayer(layer: CAShapeLayer(), color: waveColor)
            waveLayer.frame = frame
            self.layer.addSublayer(waveLayer)
            waveLayerArray.append(waveLayer)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Start wave
    */
    open func start() {
        if !_starting {
            _stop()
            _starting = true
            _stoping = false
            _waveHeight = 0
            _waveCurvature = 0
            _waveSpeed = 0

            timer = CADisplayLink(target: self, selector: #selector(wave))
            timer?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
        }
    }

    /**
     Stop wave
    */
    open func _stop(){
        if (timer != nil) {
            timer?.invalidate()
            timer = nil
        }
    }

    open func stop(){
        if !_stoping {
            _starting = false
            _stoping = true
        }
    }

    /**
     Wave animation
     */
    @objc func wave() {

        if _starting {
            if _waveHeight < waveHeight {
                _waveHeight = _waveHeight + waveHeight/100.0
                var frame = self.bounds
                frame.origin.y = frame.size.height-_waveHeight
                frame.size.height = _waveHeight
                waveLayerArray.forEach { (each) in
                    each.frame = frame
                }
                _waveCurvature = _waveCurvature + waveCurvature / 100.0
                _waveSpeed = _waveSpeed + waveSpeed / 100.0
            } else {
                _starting = false
            }
        }

        if _stoping {
          if _waveHeight > 0 {
            _waveHeight = _waveHeight - waveHeight/50.0
            var frame = self.bounds
            frame.origin.y = frame.size.height
            frame.size.height = _waveHeight
            waveLayerArray.forEach { (each) in
                each.frame = frame
            }
            _waveCurvature = _waveCurvature - waveCurvature / 50.0
            _waveSpeed = _waveSpeed - waveSpeed / 50.0
          } else {
            _stoping = false
            _stop()
          }
        }

        if abs(_waveBaseHeightRatio - waveBaseHeightRatio)>0.001{
            _waveBaseHeightRatio += baseOffset
        }else{
            _waveBaseHeightRatio = waveBaseHeightRatio
            baseOffset = 0
        }
        
        offset += _waveSpeed

        let waveCurvature_f = Float(0.01 * _waveCurvature)
        
        waveLayerArray.forEach { (each) in
            each.wave(_waveHeight: _waveHeight,
                      width: frame.width,
                      offset: Float(offset),
                      waveCurvature_f: waveCurvature_f,
                      baseHeight: self.frame.height * _waveBaseHeightRatio)
        }
    }
}


class WaveLayer: CAShapeLayer {

    convenience init(layer: Any, color:UIColor) {
        self.init(layer:layer)
        self.fillColor = color.cgColor
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var random = Float.random(in: 0.03...0.1)
    
    func wave(_waveHeight: CGFloat, width: CGFloat, offset: Float, waveCurvature_f: Float, baseHeight: CGFloat) {
        let offset_f = Float(offset * random)

        let height = CGFloat(_waveHeight)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: height - baseHeight))
        var y: CGFloat = 0
        
        for x in 0...Int(width) {
          y = height * CGFloat(sinf( waveCurvature_f * Float(x) + offset_f))
          path.addLine(to: CGPoint(x: CGFloat(x), y: y - baseHeight))
        }

        path.addLine(to: CGPoint(x: width, y: height + 1))
        path.addLine(to: CGPoint(x: 0, y: height + 1))

        path.closeSubpath()
        self.path = path
    }
}


@propertyWrapper
struct RatioRegion{
    var number: CGFloat
    init() {
        self.number = 0.5
    }
    var wrappedValue: CGFloat{
        get { return number }
        set {
            if newValue > 1{
                number = 1
            }else if newValue < 0{
                number = 0
            }else{
                number = newValue
            }
        }
    }
}

