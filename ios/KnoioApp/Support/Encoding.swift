import Foundation

extension Data {
    /// Base64-URL-Kodierung (für PKCE Code-Verifier/Challenge).
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension CharacterSet {
    /// Erlaubte Zeichen für `application/x-www-form-urlencoded`-Werte.
    static let urlFormValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=?+/")
        return set
    }()
}
