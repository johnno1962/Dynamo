
import Foundation
import Dynamo

let logger = {
    (msg: String) in
    print( msg )
}

_ = DynamoWebServer( portNumber: 8080, swiftlets: [
    LoggingSwiftlet( logger: dynamoTrace ),
    ExampleAppSwiftlet( pathPrefix: "/example" ),
    SSLProxySwiftlet( logger: logger ),
    ProxySwiftlet( logger: logger ),
    DocumentSwiftlet( documentRoot:
        "\(NSHomeDirectory())/Sites" )
] )

Thread.sleep(until: .distantFuture)
