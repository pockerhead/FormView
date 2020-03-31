//
//  FormViewSizeSource.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
// swiftlint:disable all

import UIKit
import SwiftUI

public final class FormViewSizeSource {
    
    public init() {}
    
    var cachedSizes: [String: CGSize] = [:]
    
    func size(at index: Int,
              data: ViewModelWithViewClass?,
              collectionSize: CGSize,
              dummyView: ViewModelConfigurable,
              direction: UICollectionView.ScrollDirection) -> CGSize {
        let nonNilIdentifier = "\(dummyView.self.className)_sizeAt-\(index)"
        if let cachedSize = cachedSizes[data?.id ?? nonNilIdentifier] {
            return cachedSize
        }
        if let size = dummyView.sizeWith(collectionSize, data: data) {
            cachedSizes[data?.id ?? nonNilIdentifier] = size
            return size
        }
        var targetSize = collectionSize
        var horizontalPriority = UILayoutPriority.required
        var verticalPriority = UILayoutPriority.required
        if direction == .vertical {
            dummyView.frame.size.width = targetSize.width
            verticalPriority = .fittingSizeLevel
            targetSize.height = .greatestFiniteMagnitude
        } else {
            dummyView.frame.size.height = targetSize.height
            horizontalPriority = .fittingSizeLevel
            targetSize.width = .greatestFiniteMagnitude
        }
        dummyView.configure(with: data)
        let size = dummyView.systemLayoutSizeFitting(targetSize,
                                                     withHorizontalFittingPriority: horizontalPriority,
                                                     verticalFittingPriority: verticalPriority)
        cachedSizes[data?.id ?? nonNilIdentifier] = size
        return size
    }
}
