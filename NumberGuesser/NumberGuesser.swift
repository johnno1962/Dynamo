//
// compiled from NumberGuesser.shtml
//

import Foundation
#if !os(iOS)
import Dynamo
#endif

 private let staticVar = 99

@objc (NumberGuesserSwiftlet)
public class NumberGuesserSwiftlet: SessionApplication {


    private let number = Int(arc4random()%100)+1
    private var history = [String]()

    override public func processRequest( _ out: DynamoHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {
        var response = ""

        response += "<html><head><title>Number Guesser Example</title></head>\n<body>\n    <form method=\"POST\" action=\"\(out.path)\">\n    "

        // response will be "deflated" if possible
        out.compressResponse = true

        if let guess = parameters["guess"]?.toInt() {
            if guess == number {
                clearSession()
response += "                <h3>You're right!</h3>\n                <input type=\"submit\" value=\"Play again\">\n                <a href=\"/\">Back to menu</a>\n                "

                    out.response( response )
                    return
            }
            else if guess < number  {
                history.append( "\(guess) is too low" )
            }
            else if guess > number {
                history.append( "\(guess) is too high" )
            }
        }
response += "    <h3>Thinking of a number between 1 and 100..</h3>\n    "
 for guess in history {
response += "        \(guess)<br>\n    "
 }
response += "    Enter a guess: <input type=\"textfield\" name=\"guess\">\n    <input type=\"submit\" value=\"Enter\">\n    </form>\n</body>\n</html>"

        out.response( response )
    }

}
