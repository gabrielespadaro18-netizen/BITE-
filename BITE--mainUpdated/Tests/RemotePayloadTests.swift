import Foundation

@main struct RemotePayloadTests {
    struct Response: Codable { let recipes: [Recipe] }
    static func main() throws {
        let sample = """
        {"recipes":[{"id":"simple-test","name":"Test Salad","minutes":10,"tag":"Simple","servings":2,"emoji":"🥗","hue":0.3,"blurb":"Quick salad","verified":false,"draft":true,"sourceUrl":null,"meals":["Lunch"],"ingredients":[{"name":"Tomatoes","quantity":1,"amount":"","category":"Fruit & Vegetables"}],"steps":["Chop tomatoes"],"intolerances":[],"allergens":[],"diets":[],"goals":["Save Time"],"costPerServing":1.5,"region":"Europe","country":"Italy","vibes":[],"imageURL":null}]}
        """
        let decoded = try JSONDecoder().decode(Response.self, from: Data(sample.utf8))
        precondition(decoded.recipes.count == 1)
        precondition(decoded.recipes[0].hasContent)
        precondition(decoded.recipes[0].ingredients[0].name == "Tomatoes")
        print("PASS: Airtable worker payload decodes into the iOS Recipe model")
    }
}
