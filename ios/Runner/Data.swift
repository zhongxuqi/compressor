//
//  Data.swift
//  Runner
//
//  Created by xuqi zhong on 2020/12/21.
//

import Foundation
import HandyJSON

class FileInfo: HandyJSON {
    var fileName: String = ""
    var uri: String = ""
    
    required init() {}
    
    func mapping(mapper: HelpingMapper) {
        mapper <<< self.fileName <-- "file_name"
        mapper <<< self.uri <-- "uri"
    }
}
