import Foundation

enum Config {
    // MARK: - Supabase
    static let supabaseURL = Secrets.supabaseURL.absoluteString
    static let supabaseAnonKey = Secrets.supabaseAnonKey
    
    // MARK: - Google Maps
    static let googleMapsAPIKey = Secrets.googleMapsAPIKey
    
    // MARK: - App Settings
    static let defaultSearchRadiusKm: Double = 50.0
    static let feedPageSize: Int = 20
    static let maxPhotoUploads: Int = 5
    static let handicapMultiplier: Double = 0.96

    static let universityEmailDomains: [String: String] = [
        // MARK: - California Universities
        
        // University of California (UC)
        "berkeley.edu": "UC Berkeley",
        "ucla.edu": "UCLA",
        "ucsd.edu": "UC San Diego",
        "ucsb.edu": "UC Santa Barbara",
        "uci.edu": "UC Irvine",
        "ucdavis.edu": "UC Davis",
        "ucsc.edu": "UC Santa Cruz",
        "ucr.edu": "UC Riverside",
        "ucmerced.edu": "UC Merced",
        "ucsf.edu": "UC San Francisco",
        
        // California State University (CSU) - Top & Local
        "sjsu.edu": "San Jose State",
        "sdsu.edu": "San Diego State",
        "sfsu.edu": "San Francisco State",
        "csulb.edu": "Cal State Long Beach",
        "fullerton.edu": "Cal State Fullerton",
        "csun.edu": "Cal State Northridge",
        "calpoly.edu": "Cal Poly SLO",
        "cpp.edu": "Cal Poly Pomona",
        "csus.edu": "Sacramento State",
        "fresnostate.edu": "Fresno State",
        "csueastbay.edu": "Cal State East Bay",
        "csuchico.edu": "Chico State",
        
        // Private - California
        "stanford.edu": "Stanford University",
        "usc.edu": "USC",
        "caltech.edu": "Caltech",
        "scu.edu": "Santa Clara University",
        "usfca.edu": "University of San Francisco",
        "sandiego.edu": "University of San Diego",
        "pepperdine.edu": "Pepperdine University",
        "lmu.edu": "Loyola Marymount University",
        "chapman.edu": "Chapman University",
        "claremont.edu": "Claremont Colleges",
        "pomona.edu": "Pomona College",
        "cmc.edu": "Claremont McKenna College",
        "hmc.edu": "Harvey Mudd College",
        "pitzer.edu": "Pitzer College",
        "scrippscollege.edu": "Scripps College",
        "oxy.edu": "Occidental College",
        "stmarys-ca.edu": "Saint Mary's College",
        "pacific.edu": "University of the Pacific",
        
        // MARK: - Ivy League & Top National
        "harvard.edu": "Harvard University",
        "yale.edu": "Yale University",
        "princeton.edu": "Princeton University",
        "mit.edu": "MIT",
        "duke.edu": "Duke University",
        "unc.edu": "UNC Chapel Hill",
        "columbia.edu": "Columbia University",
        "cornell.edu": "Cornell University",
        "upenn.edu": "UPenn",
        "brown.edu": "Brown University",
        "dartmouth.edu": "Dartmouth College"

        // add more as needed
    ]
}
