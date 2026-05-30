# Bulk SMS Sender - 100% Offline Android App

This project is a 100% offline, local Bulk SMS Sender Android mobile application written in Flutter. It is designed to send bulk messages via the physical SIM card(s) of an Android phone without using any external paid APIs or internet. It includes a 10-second anti-blocking timer between SMS dispatches to prevent SIM blocking by Pakistani networks (Jazz, Zong, Telenor, Ufone).

---

## 🇵🇰 APK Kaise Banayein (How to Build the APK File for Free)

Aapko apne computer par Flutter ya JDK install karne ki koi zaroorat nahi hai. Aap **GitHub Actions** (jo ke 100% free hai aur iski koi build limit nahi hai) ka use kar ke direct `.apk` file bana sakte hain.

### Step-by-Step Guide (GitHub Method):

#### 1. GitHub par Free Account aur Repository Banayein:
- **[GitHub.com](https://github.com/)** par ja kar ek free account banayein ya login karein.
- Green color ke **"New"** ya **"Create Repository"** button par click karein.
- Repository ka naam rakhein (e.g., `bulk-sms-sender`).
- Ise **Public** select karein aur niche **"Create repository"** par click karein.

#### 2. Project Files Upload Karein:
- Apne repository page par **"uploading an existing file"** ke link par click karein.
- Apne computer ke `bulk sms sender` folder ke andar se ye files/folders select kar ke drag aur drop karein:
  - `.github` (folder)
  - `android` (folder)
  - `ios` (folder)
  - `lib` (folder)
  - `pubspec.yaml` (file)
  - `README.md` (file)
- Niche green color ke **"Commit changes"** button par click karein.

#### 3. APK Auto-Build aur Download Karein:
- Files upload hone ke baad, page ke top bar me **"Actions"** tab par click karein.
- Wahan aapko **"Build Flutter APK"** workflow chalta hua dikhega (orange color ka circle ghum raha hoga).
- 2 se 3 minutes wait karein jab tak wo green tick checkmark nahi ban jata.
- Completed build par click karein aur page ke niche **"Artifacts"** section me ja kar **`release-apk`** par click kar ke apni APK download kar lein!

#### 4. APK Phone me Install Karein:
- Downloaded zip file (jis me APK hai) ko unzip karein to aapko `app-release.apk` file mil jayegi.
- Use apne phone me transfer karein.
- Phone me install karte waqt agar warning aaye ("Blocked by Play Protect" ya "Install from Unknown Sources"), to use **"Install Anyway"** / **"Allow"** karein kyunki ye ek custom build application hai.

---

## 🛠️ App Features & How to Use

1. **Excel/CSV Upload:**
   - Tap on the **Dashed Dropzone** to select your Excel file containing contacts.
   - Column A must contain the phone numbers (e.g., `03033497913`, `+923033497913`). The app automatically sanitizes and cleans the numbers.
   
2. **SIM Slot Selection:**
   - Choose between **SIM Slot 1** or **SIM Slot 2** depending on which SIM has your active local SMS package.

3. **Dynamic Placeholder Templates:**
   - Write message templates using placeholders:
     - `[Name]` -> Will be replaced by the recipient's name column.
     - `[Amount]` -> Will be replaced by the "Amount" column in your Excel.
     - `[ColumnHeader]` -> Mapped automatically from any header in your spreadsheet!
   - Example: `AoA [Name], your pending fee is Rs. [Amount].`

4. **Anti-SIM Blocking:**
   - Telecom operators block SIMs that send bulk SMS too fast. The app waits for **10 seconds** between each sent message. You can pause or resume at any time.

5. **Terminal logs:**
   - A real-time green-on-black terminal outputs everything that happens (success, failure, wait timers).
