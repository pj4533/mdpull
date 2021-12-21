import Foundation
import ArgumentParser

struct MetadataPull: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mdpull",
        abstract: "Command line app to pull Opensea style NFT metadata"
    )

    @Argument(help: "IPFS Arg Id")
    var argId: String

	@Option(name: .shortAndLong, help: "Number of tokens")
    private var numTokens: Int = 10

    @Option(name: .shortAndLong, help: "Output filename")
    private var outputFilename: String?

    @Flag(name: .shortAndLong, help: "Use Dune table format")
    var useDuneFormat = false

	func run() {
        let group = DispatchGroup()
        
        var tokenMetadata: [Metadata] = []
        let datasource = MetadataDataSource()
        let semaphore = DispatchSemaphore(value: 1)
        for i in 1...self.numTokens {
            print("Fetching Token #\(i)")
            group.enter()
            datasource.getMetadata(withArgId: self.argId, withId: i) { metadata in
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
                var traitValues: [String] = []
                for traitName in traitsSet {
                    var traitValue = "''"
                    if let thisValue = metadata.attributes?.filter({$0.traitType == traitName}).first?.value?.value as? String {
                        traitValue = self.useDuneFormat ? "'\(thisValue)'" : "\(thisValue)"
                    } else if let thisValue = metadata.attributes?.filter({$0.traitType == traitName}).first?.value?.value as? Int {
                        traitValue = "\(thisValue)"
                    }
                    traitValues.append(traitValue)
                }
                lineStrings.append("(\(index), \(traitValues.joined(separator: ", ")))")
                index += 1
            }
            if self.useDuneFormat {
                output.append("INSERT INTO VIEW cryptocoven.cryptocoven_traits (token_id, \(columnNamesForTraits.joined(separator: ", ")))\nVALUES\n")
                output.append(lineStrings.joined(separator: ",\n"))
            } else {
                output.append(lineStrings.joined(separator: ",\n"))
            }
            
            if let outputFilename = self.outputFilename {
                do {
                    let outputURL = URL(fileURLWithPath: outputFilename)
                    try output.write(to: outputURL, atomically: false, encoding: .utf8)
                } catch let error {
                    print(error.localizedDescription)
                }
            } else {
                print(output)
            }
            Foundation.exit(0)
        }

        // Run GCD main dispatcher, this function never returns, call exit() elsewhere to quit the program or it will hang
        dispatchMain()
    }
}

MetadataPull.main()
