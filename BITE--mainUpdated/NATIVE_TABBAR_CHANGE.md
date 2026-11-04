# BITE! — barra tab nativa iOS

La precedente barra personalizzata è stata sostituita in `BITE/MainTabView.swift` con `TabView` + `.tabItem` e `.tag` (iOS 17+). Il sistema iOS disegna e gestisce la tab bar: non vi sono HStack fissi, capsule selezionate, ombre o overlay custom. La tinta BITE verde si applica solamente allo stato selezionato. Le quattro sezioni mantengono gli stessi flussi.

Icone: Bite = SF Symbols `fork.knife.circle`, Recipes = SF Symbols `book.closed`, My Plan = SF Symbols `calendar`, Pantry = SF Symbols `carrot`.

Il layout di `PantryView` rimane un VStack con lista flessibile e due pulsanti in fondo. Con TabView nativa la safe area inferiore è gestita da iOS; il contenuto non deve inserirsi nella tab bar.

Per provare: apri `BITE.xcodeproj`, seleziona iPhone 17, usa Product > Clean Build Folder e Run. Verifica il cambio tab, il comportamento con 50 elementi in dispensa, la navigazione dalle schede e lo stato selezionato. Una build reale richiede Xcode su macOS.
