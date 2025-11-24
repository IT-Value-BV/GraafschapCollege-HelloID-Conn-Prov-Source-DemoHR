
# Introductie
HelloID Provisioning is een oplossing om identiteiten en accounts automatisch te beheren. Met deze koppeling importeer je **personen en contracten** uit het Demo HR-systeem naar HelloID. Dit stelt je in staat om eenvoudig te provisionen naar doelsystemen, zoals Active Directory of applicaties. De instructies hieronder zijn speciaal opgesteld voor studenten van het **Graafschap College** en zijn bedoeld voor een **demo-omgeving**.  

> **Let op:** Deze repository is bedoeld voor studenten van het **Graafschap College**. De broncode mag **niet** gebruikt worden in een productieomgeving. Alle persoonsgegevens zijn fictief en gegenereerd door AI. Gebruik deze repository **niet** in productie.

---

## Bronsysteem
Deze repository bevat alles om te koppelen met het **Demo HR-systeem** vanuit HelloID.  
Volg onderstaande stappen om de koppeling in te richten.

---

### **Toevoegen nieuw bronsysteem**  
*Hier maak je het bronsysteem aan in HelloID.*  
1. Ga naar het HelloID Provisioning administrator portaal:  
   `https://gc-bedrijfsnaam.helloid.training/provisioning`
2. Navigeer naar **Source → Systems**  
3. Klik rechtsboven op het **plus-icoon** om een nieuw bronsysteem toe te voegen  
4. Kies het template **Source Template** en maak het systeem aan  

---

### **Inrichting scripts**  
*Hier voeg je de benodigde scripts en configuratie toe.*  
1. Op het tabblad **General** kun je de naam wijzigen, bijvoorbeeld naar **Demo HR**  
2. Voeg het icoon van het bronsysteem toe 
3. Ga naar het tabblad **System**  
4. Voeg onder **Import scripts** de scripts toe:  
   - `persons.ps1`  
   - `departments.ps1`  
5. Voeg de custom connector configuratie toe:  
   - `configuration.json`  

---

### **Testen connectie & ophalen data**  
*Hier controleer je of de koppeling werkt.*  
1. Ga naar het tabblad **Configuration**  
2. Vul de configuratiewaarden in:  

| Veld                        | Waarde                          |
|----------------------------|--------------------------------|
| Azure Storage Account Name | `stgtdtestwehelloid01`         |
| Access Key                 | Ontvangen key van IT-Value     |
| Table Name Employees       | `hrDistEmployees`             |
| Table Name Contracts       | `hrDistEmployments`           |
| Table Name Departments     | `hrDistDepartments`           |
| Table Name Titles          | `hrDistTitles`                |
| Table Name Locations       | `hrDistLocations`             |

3. Klik op **Apply**  
4. Klik daarna rechtsboven op **Import raw data**  
5. Controleer op het tabblad **Raw data** of er data is ingeladen  

---

### **Configureren mapping**  
*Hier zorg je dat de data correct wordt gemapt.*  
1. Ga naar het tabblad **Persons**  
2. Klik op **Import** om de mapping te importeren  
3. Kopieer de code uit `mapping.json`, plak deze in het veld en klik op **Import**  
4. Klik op **Apply**  
5. Herhaal deze stappen voor het tabblad **Contracts**  

---

### **Configureren thresholds**  
*Thresholds voorkomen dat data onbedoeld verwijderd wordt.*  
Stel thresholds in op het tabblad **Thresholds**:  

| Threshold | Enabled | Count | Percentage |
|-----------|---------|-------|-----------|
| Addition  | Ja      | 10    | 0         |
| Removal   | Ja      | 10    | 0         |
| Blocked   | Nee     | 0     | 0         |

---

### **Publiceren eerste import**  
*Hier start je de eerste import.*  
1. Ga naar **Source → Systems**  
2. Klik op **Start import** om personen te importeren in HelloID  
3. Stel één of meerdere **schedules** in onder **Source → Schedules**  

---

Vanaf nu heb je personen en contracten geïmporteerd in je HelloID-omgeving.  
Je kunt deze gebruiken om te provisionen naar doelsystemen.

## Handige links voor extra hulp
Voor meer uitleg en verdieping kun je deze links gebruiken:  

- [Getting started with HelloID](https://www.tools4ever.nl/blog/?series%5B0%5D=getting-started-with-helloid)
- [HelloID documentatie](https://docs.helloid.com/en/provisioning.html)
