//
//  File.swift
//  
//
//  Created by PJ Gray on 12/20/21.
//

import Foundation

class MetadataDataSource {
    func getMetadata(withArgId argId: String, withId tokenId: Int, withSuccess success: ((_ metadata: Metadata) -> Void)?, failure: ((_ error: Error?) -> Void)? ) {
        // this folder structure might be project specific - could maybe pass it in?
        let url = URL(string: "https://ipfs.infura.io:5001/api/v0/cat?arg=\(argId)/\(tokenId).json")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    print("Rate limit error, waiting 1s...")
                    sleep(1)
                    self.getMetadata(withArgId: argId, withId: tokenId, withSuccess: success, failure: failure)
                } else {
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            decoder.keyDecodingStrategy = .convertFromSnakeCase
                            let response = try decoder.decode(Metadata.self, from: data)
                            success?(response)
                        } catch {
                            print("JSON Error: \(tokenId)")
                        }
                    }
                }
            }
        }
        task.resume()
    }
}
