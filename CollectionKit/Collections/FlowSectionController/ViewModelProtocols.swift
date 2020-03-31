//
//  ViewModelConfigurable.swift
//  SmartStaff
//
//  Created by artem on 20.02.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

import Foundation
import UIKit

protocol ViewModelConfigurable: UIView {
    func configure(with data: ViewModelWithViewClass?)
    func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?) -> CGSize?
    func setHighlighted(highlighted: Bool)
}

extension ViewModelConfigurable where Self: UICollectionViewCell {}

protocol ViewModelWithViewClass {
    var id: String? { get }
    var storedId: String? { get set }
    
    func viewClass() -> ViewModelConfigurable.Type
    
}

extension ViewModelConfigurable {
    
    func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?) -> CGSize? {
        nil
    }
    func setHighlighted(highlighted: Bool) {}
}

// swiftlint:disable all
extension ViewModelWithViewClass {
    
    var id: String? {
        storedId
    }
    
    var storedId: String? {
        get { nil }
        set { () }
    }
}
