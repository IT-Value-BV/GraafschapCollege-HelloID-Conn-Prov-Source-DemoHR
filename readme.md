
# Introductie
HelloID Provisioning is een oplossing om identiteiten en accounts automatisch te beheren. Met deze koppeling importeer je **personen en contracten** uit het Demo HR-systeem naar HelloID. Dit stelt je in staat om eenvoudig te provisionen naar doelsystemen, zoals Active Directory of applicaties. De instructies hieronder zijn speciaal opgesteld voor studenten van het **Graafschap College** en zijn bedoeld voor een **demo-omgeving**.  

> **Let op:** Deze repository is bedoeld voor studenten van het **Graafschap College**. De broncode mag **niet** gebruikt worden in een productieomgeving. Alle persoonsgegevens zijn fictief en gegenereerd door AI. Gebruik deze repository **niet** in productie.

---

## Bronsysteem
Deze repository bevat alles om te koppelen met het **Demo HR-systeem** vanuit HelloID. Achtergrondinformatie over het gebruik van bronsystemen is te vinden op [Importeren brondata uit een HR-systeem](https://www.tools4ever.nl/blog/2023/importeren-brondata-uit-een-hr-systeem/). 

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
2. Voeg het icoon van het bronsysteem toe:
   `https://raw.githubusercontent.com/IT-Value-BV/GraafschapCollege-HelloID-Conn-Prov-Source-DemoHR/refs/heads/main/icon.png`
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
| Tenant                     | `stgtdtestwehelloid01`         |
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
*Hier zorg je dat de data correct wordt gemapt. Meer informatie over mapping is te vinden op [Brongegevens mappen](https://www.tools4ever.nl/blog/2023/brongegevens-mappen/).* 
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

Vanaf nu heb je personen en contracten geïmporteerd in je HelloID-omgeving. Deze data kun je gebruiken in business rules en voor het aanmaken van accounts en het beheren autorisaties in doelsystemen. Tools4Ever heeft standaard koppelingen ontwikkeld voor veel applicaties. Deze zijn te vinden op [GitHub](https://github.com/Tools4everBV).

Gebruik de volgende informatie om de HelloID configuratie af te ronden. 

1. Installeren HelloID agent
- [HelloID Agent installeren en configureren](https://www.tools4ever.nl/blog/2022/helloid-agent-installeren-en-configureren/)

2. Configureren AD doelsysteem
- [Documentatie AD doelsysteem ](https://docs.helloid.com/en/provisioning/target-systems/active-directory-target-systems/add--edit--or-remove-an-active-directory-target-system.html)

3. Configureren FreshService doelsysteem
- [GraafschapCollege-HelloID-Conn-Prov-Target-FreshService-Requesters](https://github.com/IT-Value-BV/GraafschapCollege-HelloID-Conn-Prov-Target-FreshService-Requesters)

4. Configureren Business Rules
- [Business rules](https://www.tools4ever.nl/blog/2023/business-rules/)

5. Configureren notificaties en thresholds
- [Notificaties en thresholds](https://www.tools4ever.nl/blog/2023/notificaties-en-thresholds/)

## Handige links voor extra hulp
Voor meer uitleg en verdieping kun je deze links gebruiken:  

- [HelloID documentatie](https://docs.helloid.com/en/provisioning.html)
- [Logging en troubleshooting](https://www.tools4ever.nl/blog/2023/logging-en-troubleshooting/)

**GitHub**

Op de GitHub pagina's van IT-Value en Tools4Ever zijn standaard koppelingen voor HelloID gedocumenteerd.
- [IT-Value](https://github.com/IT-Value-BV)
- [Tools4Ever](https://github.com/Tools4everBV)






