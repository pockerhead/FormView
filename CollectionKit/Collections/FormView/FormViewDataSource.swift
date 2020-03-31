//
//  FormViewDataSource.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

import Foundation

typealias FormViewIdentifierMapperFn = (Int, ViewModelWithViewClass?) -> String

final class FormViewDataSource: CollectionReloadable {
    
    var data: [ViewModelWithViewClass?] {
        didSet {
            setNeedsReload()
        }
    }
    
    var identifierMapper: FormViewIdentifierMapperFn {
        didSet {
            setNeedsReload()
        }
    }
    
    public init(data: [ViewModelWithViewClass?] = [], identifierMapper: @escaping FormViewIdentifierMapperFn = { index, data in "\(data?.id ?? String(index))" }) {
        self.data = data
        self.identifierMapper = identifierMapper
    }
    
    var numberOfItems: Int {
        data.count
    }
    
    func identifier(at: Int) -> String {
        identifierMapper(at, data[at])
    }
    
    func data(at: Int) -> ViewModelWithViewClass? {
        data[at]
    }
    
}
