//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import UIKit

class UICinematicBackgroundView: UIView {
    
    private var currentImageView: UIView?
    
    private var selectDelayTimer: Timer?
    
    init(initialImageView: UIImageView) {
        super.init(frame: .zero)
        
        initialImageView.translatesAutoresizingMaskIntoConstraints = false
        initialImageView.alpha = 0
        
        addSubview(initialImageView)
        NSLayoutConstraint.activate([
            initialImageView.topAnchor.constraint(equalTo: topAnchor),
            initialImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            initialImageView.leftAnchor.constraint(equalTo: leftAnchor),
            initialImageView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        
        self.currentImageView = initialImageView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(imageView: UIImageView) {
        
        selectDelayTimer?.invalidate()
        
        selectDelayTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(delayTimerTimed), userInfo: imageView, repeats: false)
        
    }
    
    @objc private func delayTimerTimed(timer: Timer) {
        let newImageView = timer.userInfo as! UIImageView
        
        newImageView.translatesAutoresizingMaskIntoConstraints = false
        newImageView.alpha = 0
        
        addSubview(newImageView)
        NSLayoutConstraint.activate([
            newImageView.topAnchor.constraint(equalTo: topAnchor),
            newImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            newImageView.leftAnchor.constraint(equalTo: leftAnchor),
            newImageView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        
        UIView.animate(withDuration: 0.2) {
            newImageView.alpha = 1
            self.currentImageView?.alpha = 0
        } completion: { _ in
            self.currentImageView?.removeFromSuperview()
            self.currentImageView = newImageView
        }

    }
}
