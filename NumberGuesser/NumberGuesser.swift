
// compiled from NumberGuesser.shtml

import Foundation
#if os(OSX)
import Dynamo
#endif

 private let i = 99 

@objc (NumberGuesserProcessor)
public class NumberGuesserProcessor: DynamoSessionBasedApplication {


    private let number = Int(arc4random()%100)+1
    private var history = [String]()


    override public func processRequest( out: DynamoHTTPConnection, pathInfo: String, parameters: [String:String], cookies: [String:String] ) {

        out.print( "<html>\n<body>\n    <form method=\"POST\" action=\"\(out.path)\">\n    " )
 if let guess = parameters["guess"]?.toInt() {
        if guess == number {
            clearSession() 
out.print( "        <h3>You're right!</h3>\n        <input type=\"submit\" value=\"Play again\">\n        <a href=\"/\">Back to menu</a>\n            " )
 return
        }
        else if guess < number  {
            history.append( "\(guess) is too low" )
        }
        else if guess > number {
            history.append( "\(guess) is too high" )
        }
    } 
out.print( "    <h3>I'm thinking of a number between 1 and 100</h3>\n    " )
 for try in history { 
out.print( "        \(try)<br>\n    " )
 } 
out.print( "    Enter a guess: <input type=\"textfield\" name=\"guess\">\n    <input type=\"submit\" value=\"Enter\">\n    </form>\n</body>\n</html>" )
    }

}

