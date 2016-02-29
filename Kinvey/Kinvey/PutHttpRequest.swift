//
//  PutRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class PutHttpRequest: HttpRequest {
    
    override init(endpoint: Endpoint, credential: Credential? = nil, client: Client = sharedClient) {
        super.init(endpoint: endpoint, credential: credential, client: client)
        request.HTTPMethod = "PUT"
    }

}
