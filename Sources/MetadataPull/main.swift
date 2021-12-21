import Foundation
import ArgumentParser

struct MetadataPull: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mdpull",
        abstract: "Command line app to pull Opensea style NFT metadata"
    )

	func run() {
        let group = DispatchGroup()
        
        var tokenMetadata: [Metadata] = []
        let datasource = MetadataDataSource()
        let semaphore = DispatchSemaphore(value: 1)
        for i in 1...9999 {
            print("Fetching Token #\(i)")
            group.enter()
            datasource.getMetadata(withArgId: "QmSZaGTScaLwdg1j3L6FiuUxbBa3bMwbNJeme3phij9cbT", withId: i) { metadata in
                tokenMetadata.append(metadata)
                semaphore.signal()
                group.leave()
            } failure: { error in
                print("ERROR: \(error?.localizedDescription ?? "Unknown")")
                group.leave()
            }
            semaphore.wait()
            let ms = 1000
            usleep(useconds_t(200 * ms)) //will sleep for 2 milliseconds (.002 seconds)
        }

        group.notify(queue: DispatchQueue.main) {
            var output: String = ""
            
            let traitsSet = Set(tokenMetadata.compactMap({$0.attributes?.compactMap({$0.traitType})}).joined()).sorted()
            
            // this seems not very robust
            let columnNamesForTraits = traitsSet.map({$0.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "_").lowercased()})
            
            var index = 1
            var lineStrings: [String] = []
            for metadata in tokenMetadata {
                print("\(index)...\n")
                var traitValues: [String] = []
                for traitName in traitsSet {
                    var traitValue = "nil"
                    if let thisValue = metadata.attributes?.filter({$0.traitType == traitName}).first?.value?.value as? String {
                        traitValue = "'\(thisValue)'::text"
                    } else if let thisValue = metadata.attributes?.filter({$0.traitType == traitName}).first?.value?.value as? Int {
                        traitValue = "\(thisValue)::numeric"
                    }
                    traitValues.append(traitValue)
                }
                lineStrings.append("(\(index)::numeric, \(traitValues.joined(separator: ", ")))")
                index += 1
            }
            output.append("CREATE OR REPLACE VIEW dune_user_generated.my_metadata_test (token_id, \(columnNamesForTraits.joined(separator: ", ")) AS VALUES")
            output.append(lineStrings.joined(separator: ",\n"))
            
            do {
                let outputURL = URL(fileURLWithPath: "output.sql")
                try output.write(to: outputURL, atomically: false, encoding: .utf8)
            } catch let error {
                print(error.localizedDescription)
            }
        }

        // Run GCD main dispatcher, this function never returns, call exit() elsewhere to quit the program or it will hang
        dispatchMain()
    }
}

MetadataPull.main()
