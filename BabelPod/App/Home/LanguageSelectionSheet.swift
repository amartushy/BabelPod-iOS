//
//  LanguageSelectionSheet.swift
//  BabelPod
//
//  Created by Adrian Martushev on 10/19/24.
//

import SwiftUI

let englishOption = LanguageOption(name: "English (US)", image: "United States", locale: "en-US")
let spanishOption = LanguageOption(name: "Spanish (MX)", image: "Mexico", locale: "es-MX")

struct LanguageSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var translationVM : TranslationViewModel
    
    @State var showLanguageOptions = false
    @State var languageKey: String = ""
    
    var body: some View {
        
        ZStack {
            VStack(alignment : .leading, spacing : 40) {
                
                HStack {
                    Spacer()
                    Button {
                        dismiss()  
                    } label : {
                        CircularIcon(icon: "xmark")
                    }
                }
                
                VStack(alignment : .leading) {
                    Text("Translate From:")
                        .font(.custom("Raleway-SemiBold", size: 24))
                    
                    Button {
                        languageKey = "sourceLanguage"
                        showLanguageOptions = true
                    } label: {
                        LanguageOptionPreview(languageOption : translationVM.sourceLanguage )
                    }
                }
                
                VStack(alignment : .leading) {
                    Text("To:")
                        .font(.custom("Raleway-SemiBold", size: 24))
                    
                    Button {
                        languageKey = "targetLanguage"
                        showLanguageOptions = true

                    } label : {
                        LanguageOptionPreview(languageOption : translationVM.targetLanguage )
                    }
                }
                
                Spacer()
                
            }
            .padding()
            .background(Color.background)
            .overlay {
                Color(showLanguageOptions ? .black.opacity(0.5) : .clear)
                    .edgesIgnoringSafeArea(.all)
            }
            
            LanguageOptionsModal(languageToUpdate: $languageKey, isPresented: $showLanguageOptions)
                .centerGrowingModal(isPresented: showLanguageOptions)
        }
    }
}

struct LanguageOptionPreview : View {
    var languageOption : LanguageOption
    
    var showSelector : Bool = false
    
    var body: some View {
        HStack {
            Image(languageOption.image)
                .resizable()
                .scaledToFit()
                .frame(width : 30, height : 30)
            
            Text(languageOption.name)
                .font(.custom("Raleway", size: 20))
            Spacer()
            
            if showSelector {
                Image(systemName: "circle")
            } else {
                Image(systemName: "chevron.up.chevron.down")
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background(.onyx.opacity(0.6))
        .cornerRadius(10)
    }
}


struct BabelTextField: View {
    @Binding var text: String
    var icon: String
    var placeholder: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.onyx))
                .frame(height: 50)

            HStack {
                Image(systemName: icon)
                    .font(Font.custom("SF Pro", size: 14))
                    .foregroundColor(.white)
                    .padding(.leading)
                
                Spacer()
            }
            .padding(.trailing)
            
            TextField(placeholder, text: $text)
                .font(.custom("Raleway", size: 14))
                .focused($isFocused)
                .contentShape(RoundedRectangle(cornerRadius: 5))
                .onTapGesture {
                    isFocused = true
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 40)
                .frame(height: 50)
        }
        .frame(height: 44)
    }
}



struct LanguageOptionsModal : View {
    @EnvironmentObject var translationsVM : TranslationViewModel
    @Binding var languageToUpdate : String
    @Binding var isPresented : Bool
    
    @State var query : String = ""
    
    var filteredLanguages: [LanguageOption] {
        if query.isEmpty {
            return languages
        } else {
            return languages.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
    }
    
    var body: some View {
        VStack(alignment : .leading, spacing : 16) {
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label : {
                        CircularIcon(icon: "xmark")
                    }
                }
                
                BabelTextField(text: $query, icon: "magnifyingglass", placeholder: "Search languages..")
            }
            

            ScrollView {
                ForEach(filteredLanguages, id : \.name) { language in
                    Button {
                        if languageToUpdate == "sourceLanguage" {
                            translationsVM.sourceLanguage = language
                        } else {
                            translationsVM.targetLanguage = language
                        }
                        isPresented = false
                    } label: {
                        LanguageOptionPreview(languageOption: language, showSelector : true)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(10)
        .padding(20)
    }
}

struct LanguageOption {
    let name: String
    let image: String
    let locale: String
}


let languages: [LanguageOption] = [
    LanguageOption(name: "Albanian", image: "Albania", locale: "sq-AL"),
    LanguageOption(name: "Arabic (Algeria)", image: "Algeria", locale: "ar-DZ"),
    LanguageOption(name: "Portuguese (Angola)", image: "Angola", locale: "pt-AO"),
    LanguageOption(name: "English (Antigua)", image: "Antigua", locale: "en-AG"),
    LanguageOption(name: "Spanish (Argentina)", image: "Argentina", locale: "es-AR"),
    LanguageOption(name: "Armenian", image: "Armenia", locale: "hy-AM"),
    LanguageOption(name: "English (Australia)", image: "Australia", locale: "en-AU"),
    LanguageOption(name: "German (Austria)", image: "Austria", locale: "de-AT"),
    LanguageOption(name: "Azerbaijani", image: "Azerbaijan", locale: "az-AZ"),
    LanguageOption(name: "English (Bahamas)", image: "Bahamas", locale: "en-BS"),
    LanguageOption(name: "Arabic (Bahrain)", image: "Bahrain", locale: "ar-BH"),
    LanguageOption(name: "Bengali (Bangladesh)", image: "Bangladesh", locale: "bn-BD"),
    LanguageOption(name: "English (Barbados)", image: "Barbados", locale: "en-BB"),
    LanguageOption(name: "Belarusian", image: "Belarus", locale: "be-BY"),
    LanguageOption(name: "Dutch (Belgium)", image: "Belgium", locale: "nl-BE"),
    LanguageOption(name: "French (Benin)", image: "Benin", locale: "fr-BJ"),
    LanguageOption(name: "Spanish (Bolivia)", image: "Bolivia", locale: "es-BO"),
    LanguageOption(name: "English (Botswana)", image: "Botswana", locale: "en-BW"),
    LanguageOption(name: "Portuguese (Brazil)", image: "Brazil", locale: "pt-BR"),
    LanguageOption(name: "Malay (Brunei)", image: "Brunei", locale: "ms-BN"),
    LanguageOption(name: "Bulgarian", image: "Bulgaria", locale: "bg-BG"),
    LanguageOption(name: "French (Burkina Faso)", image: "Burkina Faso", locale: "fr-BF"),
    LanguageOption(name: "French (Burundi)", image: "Burundi", locale: "fr-BI"),
    LanguageOption(name: "French (Cameroon)", image: "Cameroon", locale: "fr-CM"),
    LanguageOption(name: "English (Canada)", image: "Canada", locale: "en-CA"),
    LanguageOption(name: "Portuguese (Cape Verde)", image: "Cape Verde", locale: "pt-CV"),
    LanguageOption(name: "French (Central African Republic)", image: "Central African Republic", locale: "fr-CF"),
    LanguageOption(name: "French (Chad)", image: "Chad", locale: "fr-TD"),
    LanguageOption(name: "Spanish (Chile)", image: "Chile", locale: "es-CL"),
    LanguageOption(name: "Chinese (Simplified)", image: "China", locale: "zh-CN"),
    LanguageOption(name: "Spanish (Colombia)", image: "Colombia", locale: "es-CO"),
    LanguageOption(name: "Arabic (Comoros)", image: "Comoros", locale: "ar-KM"),
    LanguageOption(name: "French (Congo)", image: "Congo", locale: "fr-CG"),
    LanguageOption(name: "Spanish (Costa Rica)", image: "Costa Rica", locale: "es-CR"),
    LanguageOption(name: "French (Côte d'Ivoire)", image: "Côte d'Ivoire", locale: "fr-CI"),
    LanguageOption(name: "Croatian", image: "Croatia", locale: "hr-HR"),
    LanguageOption(name: "Spanish (Cuba)", image: "Cuba", locale: "es-CU"),
    LanguageOption(name: "Greek (Cyprus)", image: "Cyprus", locale: "el-CY"),
    LanguageOption(name: "Czech", image: "Czech Republic", locale: "cs-CZ"),
    LanguageOption(name: "Danish", image: "Denmark", locale: "da-DK"),
    LanguageOption(name: "French (Djibouti)", image: "Djibouti", locale: "fr-DJ"),
    LanguageOption(name: "Arabic (Egypt)", image: "Egypt", locale: "ar-EG"),
    LanguageOption(name: "Spanish (Equatorial Guinea)", image: "Equatorial Guinea", locale: "es-GQ"),
    LanguageOption(name: "Tigrinya (Eritrea)", image: "Eritrea", locale: "ti-ER"),
    LanguageOption(name: "Estonian", image: "Estonia", locale: "et-EE"),
    LanguageOption(name: "English (Eswatini)", image: "Eswatini", locale: "en-SZ"),
    LanguageOption(name: "Amharic (Ethiopia)", image: "Ethiopia", locale: "am-ET"),
    LanguageOption(name: "Finnish", image: "Finland", locale: "fi-FI"),
    LanguageOption(name: "French", image: "France", locale: "fr-FR"),
    LanguageOption(name: "French (Gabon)", image: "Gabon", locale: "fr-GA"),
    LanguageOption(name: "English (Gambia)", image: "Gambia", locale: "en-GM"),
    LanguageOption(name: "Georgian", image: "Georgia", locale: "ka-GE"),
    LanguageOption(name: "German", image: "Germany", locale: "de-DE"),
    LanguageOption(name: "English (Ghana)", image: "Ghana", locale: "en-GH"),
    LanguageOption(name: "Greek", image: "Greece", locale: "el-GR"),
    LanguageOption(name: "English (Grenada)", image: "Grenada", locale: "en-GD"),
    LanguageOption(name: "English (Guyana)", image: "Guyana", locale: "en-GY"),
    LanguageOption(name: "Portuguese (Guinea-Bissau)", image: "Guinea-Bissau", locale: "pt-GW"),
    LanguageOption(name: "French (Guinea)", image: "Guinea", locale: "fr-GN"),
    LanguageOption(name: "Spanish (Honduras)", image: "Honduras", locale: "es-HN"),
    LanguageOption(name: "Hungarian", image: "Hungary", locale: "hu-HU"),
    LanguageOption(name: "Icelandic", image: "Iceland", locale: "is-IS"),
    LanguageOption(name: "Hindi", image: "India", locale: "hi-IN"),
    LanguageOption(name: "Indonesian", image: "Indonesia", locale: "id-ID"),
    LanguageOption(name: "Persian (Iran)", image: "Iran", locale: "fa-IR"),
    LanguageOption(name: "English (Ireland)", image: "Ireland", locale: "en-IE"),
    LanguageOption(name: "Hebrew", image: "Israel", locale: "he-IL"),
    LanguageOption(name: "Italian", image: "Italy", locale: "it-IT"),
    LanguageOption(name: "English (Jamaica)", image: "Jamaica", locale: "en-JM"),
    LanguageOption(name: "Japanese", image: "Japan", locale: "ja-JP"),
    LanguageOption(name: "Arabic (Jordan)", image: "Jordan", locale: "ar-JO"),
    LanguageOption(name: "Kazakh", image: "Kazakhstan", locale: "kk-KZ"),
    LanguageOption(name: "Swahili (Kenya)", image: "Kenya", locale: "sw-KE"),
    LanguageOption(name: "Arabic (Kuwait)", image: "Kuwait", locale: "ar-KW"),
    LanguageOption(name: "Kyrgyz", image: "Kyrgyzstan", locale: "ky-KG"),
    LanguageOption(name: "Lao", image: "Laos", locale: "lo-LA"),
    LanguageOption(name: "Latvian", image: "Latvia", locale: "lv-LV"),
    LanguageOption(name: "Arabic (Lebanon)", image: "Lebanon", locale: "ar-LB"),
    LanguageOption(name: "Sesotho (Lesotho)", image: "Lesotho", locale: "st-LS"),
    LanguageOption(name: "Arabic (Libya)", image: "Libya", locale: "ar-LY"),
    LanguageOption(name: "Lithuanian", image: "Lithuania", locale: "lt-LT"),
    LanguageOption(name: "Luxembourgish", image: "Luxembourg", locale: "lb-LU"),
    LanguageOption(name: "Malagasy (Madagascar)", image: "Madagascar", locale: "mg-MG"),
    LanguageOption(name: "English (Malawi)", image: "Malawi", locale: "en-MW"),
    LanguageOption(name: "Malay", image: "Malaysia", locale: "ms-MY"),
    LanguageOption(name: "Dhivehi (Maldives)", image: "Maldives", locale: "dv-MV"),
    LanguageOption(name: "French (Mali)", image: "Mali", locale: "fr-ML"),
    LanguageOption(name: "Maltese", image: "Malta", locale: "mt-MT"),
    LanguageOption(name: "Arabic (Mauritania)", image: "Mauritania", locale: "ar-MR"),
    LanguageOption(name: "English (Mauritius)", image: "Mauritius", locale: "en-MU"),
    LanguageOption(name: "Mongolian", image: "Mongolia", locale: "mn-MN"),
    LanguageOption(name: "Arabic (Morocco)", image: "Morocco", locale: "ar-MA"),
    LanguageOption(name: "Portuguese (Mozambique)", image: "Mozambique", locale: "pt-MZ"),
    LanguageOption(name: "Burmese", image: "Myanmar", locale: "my-MM"),
    LanguageOption(name: "English (Namibia)", image: "Namibia", locale: "en-NA"),
    LanguageOption(name: "Nepali", image: "Nepal", locale: "ne-NP"),
    LanguageOption(name: "Dutch", image: "Netherlands", locale: "nl-NL"),
    LanguageOption(name: "English (New Zealand)", image: "New Zealand", locale: "en-NZ"),
    LanguageOption(name: "French (Niger)", image: "Niger", locale: "fr-NE"),
    LanguageOption(name: "English (Nigeria)", image: "Nigeria", locale: "en-NG"),
    LanguageOption(name: "Macedonian", image: "North Macedonia", locale: "mk-MK"),
    LanguageOption(name: "Norwegian", image: "Norway", locale: "no-NO"),
    LanguageOption(name: "Arabic (Oman)", image: "Oman", locale: "ar-OM"),
    LanguageOption(name: "Urdu", image: "Pakistan", locale: "ur-PK"),
    LanguageOption(name: "Spanish (Panama)", image: "Panama", locale: "es-PA"),
    LanguageOption(name: "English (Papua New Guinea)", image: "Papua New Guinea", locale: "en-PG"),
    LanguageOption(name: "Spanish (Paraguay)", image: "Paraguay", locale: "es-PY"),
    LanguageOption(name: "Filipino", image: "Philippines", locale: "fil-PH"),
    LanguageOption(name: "Polish", image: "Poland", locale: "pl-PL"),
    LanguageOption(name: "Arabic (Qatar)", image: "Qatar", locale: "ar-QA"),
    LanguageOption(name: "Romanian", image: "Romania", locale: "ro-RO"),
    LanguageOption(name: "Russian", image: "Russian Federation", locale: "ru-RU"),
    LanguageOption(name: "Kinyarwanda (Rwanda)", image: "Rwanda", locale: "rw-RW"),
    LanguageOption(name: "English (Saint Lucia)", image: "Saint Lucia", locale: "en-LC"),
    LanguageOption(name: "English (Saint Vincent & the Grenadines)", image: "Saint Vincent & the Grenadines", locale: "en-VC"),
    LanguageOption(name: "Samoan", image: "Samoa", locale: "sm-WS"),
    LanguageOption(name: "Portuguese (São Tomé & Príncipe)", image: "São Tomé & Príncipe", locale: "pt-ST"),
    LanguageOption(name: "Arabic (Saudi Arabia)", image: "Saudi Arabia", locale: "ar-SA"),
    LanguageOption(name: "French (Senegal)", image: "Senegal", locale: "fr-SN"),
    LanguageOption(name: "French (Seychelles)", image: "Seychelles", locale: "fr-SC"),
    LanguageOption(name: "English (Sierra Leone)", image: "Sierra Leone", locale: "en-SL"),
    LanguageOption(name: "English (Singapore)", image: "Singapore", locale: "en-SG"),
    LanguageOption(name: "Slovak", image: "Slovakia", locale: "sk-SK"),
    LanguageOption(name: "Slovenian", image: "Slovenia", locale: "sl-SI"),
    LanguageOption(name: "English (Solomon Islands)", image: "Solomon Islands", locale: "en-SB"),
    LanguageOption(name: "English (South Africa)", image: "South Africa", locale: "en-ZA"),
    LanguageOption(name: "Korean", image: "South Korea", locale: "ko-KR"),
    LanguageOption(name: "Spanish (Spain)", image: "Spain", locale: "es-ES"),
    LanguageOption(name: "Sinhala (Sri Lanka)", image: "Sri Lanka", locale: "si-LK"),
    LanguageOption(name: "English (St. Kitts & Nevis)", image: "St. Kitts & Nevis", locale: "en-KN"),
    LanguageOption(name: "Dutch (Suriname)", image: "Suriname", locale: "nl-SR"),
    LanguageOption(name: "Swedish", image: "Sweden", locale: "sv-SE"),
    LanguageOption(name: "German (Switzerland)", image: "Switzerland", locale: "de-CH"),
    LanguageOption(name: "Arabic (Syria)", image: "Syria", locale: "ar-SY"),
    LanguageOption(name: "Tajik", image: "Tajikistan", locale: "tg-TJ"),
    LanguageOption(name: "Swahili (Tanzania)", image: "Tanzania", locale: "sw-TZ"),
    LanguageOption(name: "Thai", image: "Thailand", locale: "th-TH"),
    LanguageOption(name: "French (Togo)", image: "Togo", locale: "fr-TG"),
    LanguageOption(name: "English (Trinidad & Tobago)", image: "Trinidad & Tobago", locale: "en-TT"),
    LanguageOption(name: "Arabic (Tunisia)", image: "Tunisia", locale: "ar-TN"),
    LanguageOption(name: "Turkish", image: "Turkey", locale: "tr-TR"),
    LanguageOption(name: "Ukrainian", image: "Ukraine", locale: "uk-UA"),
    LanguageOption(name: "Arabic (United Arab Emirates)", image: "United Arab Emirates", locale: "ar-AE"),
    LanguageOption(name: "English (United Kingdom)", image: "United Kingdom", locale: "en-GB"),
    LanguageOption(name: "English (United States)", image: "United States", locale: "en-US"),
    LanguageOption(name: "Spanish (Uruguay)", image: "Uruguay", locale: "es-UY"),
    LanguageOption(name: "Uzbek", image: "Uzbekistan", locale: "uz-UZ"),
    LanguageOption(name: "Bislama (Vanuatu)", image: "Vanuatu", locale: "bi-VU"),
    LanguageOption(name: "Spanish (Venezuela)", image: "Venezuela", locale: "es-VE"),
    LanguageOption(name: "Vietnamese", image: "Vietnam", locale: "vi-VN"),
    LanguageOption(name: "Arabic (Yemen)", image: "Yemen", locale: "ar-YE"),
    LanguageOption(name: "English (Zambia)", image: "Zambia", locale: "en-ZM")
]


#Preview {
    LanguageSelectionSheet()
}
