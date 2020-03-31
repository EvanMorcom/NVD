import Foundation
import UIKit

struct Person {
    let name: String!
    let affiliation: String!
    let profileImage: UIImage!
}

class Data {
    public var people = [
        Person(name: "Evan Morcom", affiliation: "Mecha. Engineering Student", profileImage: UIImage(named: "trackkLogo")),
        Person(name: "Alex Dreidger", affiliation: "Comp. Engineering Student", profileImage: UIImage(named: "trackkLogo")),
        Person(name: "Jeffery Hou", affiliation: "Mech. Engineering Student", profileImage: UIImage(named: "trackkLogo")),
        Person(name: "Ryan Lee", affiliation: "Mecha. Engineering Student", profileImage: UIImage(named: "trackkLogo")),
        Person(name: "Sebastian Mendo", affiliation: "Funnel Hacker", profileImage: UIImage(named: "trackkLogo")),
        Person(name: "Shirley Guo", affiliation: "Financials Legend", profileImage: UIImage(named: "trackkLogo")),
        
    ]
}
