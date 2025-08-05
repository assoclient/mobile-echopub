// Fichier utilitaire pour les codes téléphoniques internationaux
// Source: https://countrycode.org/ et https://en.wikipedia.org/wiki/List_of_country_calling_codes

String getDialCodeFromCountry(String? iso) {
  switch (iso?.toUpperCase()) {
    case 'CM': return '+237'; // Cameroun
    case 'FR': return '+33'; // France
    case 'CI': return '+225'; // Côte d'Ivoire
    case 'SN': return '+221'; // Sénégal
    case 'TG': return '+228'; // Togo
    case 'GA': return '+241'; // Gabon
    case 'CD': return '+243'; // RDC
    case 'BJ': return '+229'; // Bénin
    case 'NE': return '+227'; // Niger
    case 'NG': return '+234'; // Nigeria
    case 'US': return '+1'; // USA
    case 'CA': return '+1'; // Canada
    case 'GB': return '+44'; // Royaume-Uni
    case 'DE': return '+49'; // Allemagne
    case 'IT': return '+39'; // Italie
    case 'ES': return '+34'; // Espagne
    case 'PT': return '+351'; // Portugal
    case 'BE': return '+32'; // Belgique
    case 'CH': return '+41'; // Suisse
    case 'RU': return '+7'; // Russie
    case 'IN': return '+91'; // Inde
    case 'CN': return '+86'; // Chine
    case 'JP': return '+81'; // Japon
    case 'BR': return '+55'; // Brésil
    case 'AR': return '+54'; // Argentine
    case 'MX': return '+52'; // Mexique
    case 'DZ': return '+213'; // Algérie
    case 'MA': return '+212'; // Maroc
    case 'TN': return '+216'; // Tunisie
    case 'EG': return '+20'; // Égypte
    case 'ZA': return '+27'; // Afrique du Sud
    case 'KE': return '+254'; // Kenya
    case 'GH': return '+233'; // Ghana
    case 'ML': return '+223'; // Mali
    case 'BF': return '+226'; // Burkina Faso
    case 'GN': return '+224'; // Guinée
    case 'SL': return '+232'; // Sierra Leone
    case 'LR': return '+231'; // Libéria
    case 'ET': return '+251'; // Éthiopie
    case 'SD': return '+249'; // Soudan
    case 'SS': return '+211'; // Soudan du Sud
    case 'UG': return '+256'; // Ouganda
    case 'TZ': return '+255'; // Tanzanie
    case 'RW': return '+250'; // Rwanda
    case 'BI': return '+257'; // Burundi
    case 'MW': return '+265'; // Malawi
    case 'ZM': return '+260'; // Zambie
    case 'ZW': return '+263'; // Zimbabwe
    case 'AO': return '+244'; // Angola
    case 'CMR': return '+237'; // Cameroun (variante)
    case 'AE': return '+971'; // Émirats Arabes Unis
    case 'TR': return '+90'; // Turquie
    case 'NL': return '+31'; // Pays-Bas
    case 'SE': return '+46'; // Suède
    case 'NO': return '+47'; // Norvège
    case 'FI': return '+358'; // Finlande
    case 'PL': return '+48'; // Pologne
    case 'RO': return '+40'; // Roumanie
    case 'HU': return '+36'; // Hongrie
    case 'CZ': return '+420'; // Tchéquie
    case 'SK': return '+421'; // Slovaquie
    case 'UA': return '+380'; // Ukraine
    case 'BY': return '+375'; // Biélorussie
    case 'LT': return '+370'; // Lituanie
    case 'LV': return '+371'; // Lettonie
    case 'EE': return '+372'; // Estonie
    case 'IE': return '+353'; // Irlande
    case 'IS': return '+354'; // Islande
    case 'LU': return '+352'; // Luxembourg
    case 'MC': return '+377'; // Monaco
    case 'LI': return '+423'; // Liechtenstein
    case 'AT': return '+43'; // Autriche
    case 'AU': return '+61'; // Australie
    case 'NZ': return '+64'; // Nouvelle-Zélande
    case 'SG': return '+65'; // Singapour
    case 'MY': return '+60'; // Malaisie
    case 'TH': return '+66'; // Thaïlande
    case 'KR': return '+82'; // Corée du Sud
    case 'PH': return '+63'; // Philippines
    case 'PK': return '+92'; // Pakistan
    case 'BD': return '+880'; // Bangladesh
    case 'VN': return '+84'; // Vietnam
    case 'IL': return '+972'; // Israël
    case 'IR': return '+98'; // Iran
    case 'IQ': return '+964'; // Irak
    case 'SY': return '+963'; // Syrie
    case 'JO': return '+962'; // Jordanie
    case 'LB': return '+961'; // Liban
    case 'QA': return '+974'; // Qatar
    case 'YE': return '+967'; // Yémen
    case 'AF': return '+93'; // Afghanistan
    case 'NP': return '+977'; // Népal
    case 'LK': return '+94'; // Sri Lanka
    case 'MM': return '+95'; // Birmanie
    case 'KH': return '+855'; // Cambodge
    case 'LA': return '+856'; // Laos
    case 'TW': return '+886'; // Taïwan
    case 'HK': return '+852'; // Hong Kong
    case 'MO': return '+853'; // Macao
    case 'YE': return '+967'; // Yémen
    case 'JO': return '+962'; // Jordanie
    case 'LB': return '+961'; // Liban
    case 'PS': return '+970'; // Palestine
    case 'QA': return '+974'; // Qatar
    // doublons supprimés
    case 'BH': return '+973'; // Bahreïn
    case 'GE': return '+995'; // Géorgie
    case 'AM': return '+374'; // Arménie
    case 'AZ': return '+994'; // Azerbaïdjan
    case 'MD': return '+373'; // Moldavie
    case 'AL': return '+355'; // Albanie
    case 'SI': return '+386'; // Slovénie
    case 'BG': return '+359'; // Bulgarie
    case 'CY': return '+357'; // Chypre
    case 'MT': return '+356'; // Malte
    case 'LV': return '+371'; // Lettonie
    case 'LT': return '+370'; // Lituanie
    case 'FI': return '+358'; // Finlande
    case 'SE': return '+46'; // Suède
    case 'NO': return '+47'; // Norvège
    case 'DK': return '+45'; // Danemark
    case 'GL': return '+299'; // Groenland
    case 'FO': return '+298'; // Îles Féroé
    case 'SJ': return '+47'; // Svalbard et Jan Mayen
    case 'AX': return '+358'; // Îles Åland
    // Ajoute d'autres pays si besoin
    default: return '+237'; // Par défaut Cameroun
  }
}
