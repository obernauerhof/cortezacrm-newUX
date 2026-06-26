# Konzept: AA University & Content Delivery Framework

> **Status:** Konzeptentwurf für Vorstellung / Diskussion
> **Stand:** 2026-06-26
> **Kontext:** Marketplace & Content Delivery Framework (CortezaCRM new UX)

---

## 1. Management Summary (für die Vorstellung)

Die **AA University** ist eine Lernplattform innerhalb des CRM. Content-Ersteller
hinterlegen Lerninhalte (v.a. Video-Sequenzen) strukturiert in Lernpfaden. Der
Nutzer durchläuft diese Inhalte, sein Fortschritt wird getrackt, nach jeder
Sequenz wird sein Wissen über unsere **Question-Engine** (Fragebogen) abgefragt
und bepunktet (Score). Ein **KI-Assistent (AA-Bot)** begleitet den Nutzer:

1. **Vorab** führt der Bot ein kurzes Onboarding-Gespräch / einen Fragebogen
   durch („Was weißt du schon? Was erwartest du?") und schlägt daraus einen
   passenden Lernpfad vor.
2. **Während** des Lernens empfiehlt die KI – abhängig von Antworten, Score und
   Lückenanalyse – die jeweils nächste sinnvolle Video-Sequenz (adaptives Lernen).

Die **AA University** ist dabei der erste konkrete Anwendungsfall des größeren
**Content Delivery Frameworks**: ein generischer Mechanismus, über den Inhalte
(Kurse, Wissensartikel, später ggf. Templates/Automationen) erstellt, im
**Marketplace** angeboten und an Mandanten/Nutzer ausgeliefert werden.

**Der rote Faden:** *Content erstellen → über Marketplace verteilen → über
Content Delivery Framework ausliefern → in der AA University konsumieren,
tracken, abfragen, KI-gestützt steuern.*

---

## 2. Wo stehen wir? (ehrliche Standortbestimmung)

| Baustein | Status | Anmerkung |
|---|---|---|
| Marketplace | Idee / Branch angelegt | Im Repo noch kein Code |
| Content Delivery Framework | Idee / Branch angelegt | Im Repo noch kein Code |
| AA University | Konzept (dieses Dokument) | Noch nicht implementiert |
| Question-Engine | **vorhanden** (bestehende Funktionalität, wiederverwendbar) | Wird als Baustein integriert |
| KI/Bot-Anbindung | konzeptionell | Setzt vorhandene KI-Infrastruktur voraus |

> **Einordnung:** Das `cortezacrm-newUX`-Repository enthält aktuell ausschließlich
> die LICENSE. Der Branch `claude/aa-university-content-delivery-4qxlvn`
> markiert die Absicht, ist aber inhaltlich leer. Dieses Konzept ist die
> Grundlage, um den Scope vor der Umsetzung zu schärfen.

---

## 3. Personas & Rollen

| Rolle | Beschreibung | Kern-Bedürfnis |
|---|---|---|
| **Content Creator / Trainer** | Erstellt Kurse, lädt Video-Sequenzen hoch, definiert Fragen & Lernpfade | Einfaches Autorentool, Wiederverwendbarkeit |
| **Lernender (Mitarbeiter)** | Konsumiert Inhalte, beantwortet Fragen, sammelt Punkte | Relevante, passgenaue Inhalte ohne Überforderung |
| **Manager / Teamlead** | Sieht Fortschritt & Scores des Teams | Überblick, Skill-Gap-Erkennung, Nachweis (Compliance) |
| **Marketplace-Anbieter** | Bietet Kurspakete an (intern/extern) | Distribution, ggf. Lizenzierung |
| **AA-Bot (KI)** | Onboarding-Dialog, adaptive Empfehlungen | Verständnis von Wissensstand & Zielen |

---

## 4. User Journey (das Herzstück für die Vorstellung)

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. ONBOARDING / ASSESSMENT                                          │
│     KI-Bot-Dialog ODER Fragebogen:                                   │
│     "Was weißt du schon?"  ·  "Was möchtest du erreichen?"           │
│           │                                                          │
│           ▼                                                          │
│  2. EMPFOHLENER LERNPFAD                                             │
│     KI schlägt initiale Reihenfolge der Video-Sequenzen vor          │
│           │                                                          │
│           ▼                                                          │
│  3. VIDEO-SEQUENZ ANSEHEN                                            │
│     Player + Fortschritts-Tracking (gesehen / nicht gesehen / %)     │
│           │                                                          │
│           ▼                                                          │
│  4. WISSENS-CHECK (Question-Engine)                                  │
│     Fragen nach der Sequenz → Antworten → Score                      │
│           │                                                          │
│           ▼                                                          │
│  5. ADAPTIVE EMPFEHLUNG                                              │
│     KI wertet Antworten/Score aus:                                   │
│       · gut  → nächste/weiterführende Sequenz                        │
│       · Lücke → Wiederholung / vertiefende Sequenz                   │
│           │                                                          │
│           └──────────────► zurück zu Schritt 3 (Loop)               │
│                                                                      │
│  6. ABSCHLUSS / ZERTIFIKAT / GESAMT-SCORE                            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 5. Funktionale Bausteine

### 5.1 Content-Erstellung (Autorentool)
- Kurs / Lernpfad anlegen (Titel, Beschreibung, Zielgruppe, Tags/Skills)
- Video-Sequenzen hinterlegen (Upload oder Einbettung, z.B. Vimeo/YouTube/intern)
- Reihenfolge & Abhängigkeiten definieren (Voraussetzungen, „freischalten nach …")
- Fragen je Sequenz hinterlegen (über bestehende **Question-Engine**)
- Metadaten für KI: Lernziele, abgedeckte Skills, Schwierigkeitsgrad

### 5.2 Tracking (gesehen / nicht gesehen)
- Pro Nutzer & Sequenz: Status (`nicht begonnen` / `in Arbeit` / `abgeschlossen`)
- Abspielfortschritt in % (Resume-Funktion: weiterschauen wo aufgehört)
- Zeitstempel, Anzahl Wiederholungen
- Aggregat: Kurs-Fortschritt, Gesamt-Score, Skill-Abdeckung

### 5.3 Wissens-Check & Scoring (Question-Engine)
- Wiederverwendung der **bestehenden Question-Funktionalität**
- Fragen-Typen: Single/Multiple Choice, ggf. Freitext (KI-bewertet)
- Punktevergabe pro Frage → Sequenz-Score → Kurs-Score
- Score fließt in Empfehlungslogik **und** in Manager-Reporting

### 5.4 KI-Assistent (AA-Bot)
- **Pre-Assessment-Dialog:** konversationelles Abfragen von Vorwissen & Zielen
- **Adaptive Empfehlung:** Next-best-Sequenz auf Basis von Antworten + Score +
  bereits gesehenen Inhalten + Skill-Gaps
- **Begleitung:** Rückfragen beantworten, Inhalte zusammenfassen
- Technisch: Anbindung an Claude (siehe Architektur), Inhalte/Metadaten als Kontext

### 5.5 Marketplace & Delivery
- Kurse als „Pakete" im Marketplace listbar (intern; perspektivisch extern)
- Content Delivery Framework: Auslieferung an Mandant/Rolle/Nutzer
- Versionierung von Inhalten, Sichtbarkeits-/Berechtigungssteuerung

---

## 6. Datenmodell (Vorschlag, Corteza-Module)

Da CortezaCRM auf einem Low-Code-Modell-Ansatz basiert, lässt sich das als Set
von Modulen (Entitäten) mit Relationen abbilden:

| Modul | Wichtige Felder | Relationen |
|---|---|---|
| **Course** (Kurs/Lernpfad) | Titel, Beschreibung, Zielgruppe, Skills, Status, Version | → hat viele Sequences |
| **VideoSequence** | Titel, Video-URL/Asset, Dauer, Reihenfolge, Lernziele, Schwierigkeit | → gehört zu Course; → hat Questions |
| **Question** (bestehend) | Fragetext, Typ, Antwortoptionen, korrekte Antwort, Punkte | → gehört zu Sequence |
| **Enrollment** | Nutzer, Kurs, Startdatum, Status, Gesamt-Score | verbindet User ↔ Course |
| **Progress / Tracking** | Nutzer, Sequence, Status, Fortschritt %, letzte Position, Wiederholungen | verbindet User ↔ Sequence |
| **AnswerResult** | Nutzer, Question, gegebene Antwort, erreichte Punkte, Zeitpunkt | verbindet User ↔ Question |
| **AssessmentSession** | Nutzer, Eingangs-Antworten, KI-Empfehlung, Ziel-Skills | Pre-Assessment-Ergebnis |
| **MarketplaceListing** | Course-Ref, Anbieter, Sichtbarkeit, Lizenz/Preis, Version | → referenziert Course |

> Hinweis: „Question" als bestehendes Modul wiederverwenden statt neu bauen –
> spart Aufwand und hält Bewertungslogik konsistent.

---

## 7. Technische Architektur (high-level)

```
┌──────────────────────────────────────────────────────────────┐
│  Frontend (new UX, Vue)                                       │
│   · University-Bereich: Kursliste, Player, Wissens-Check      │
│   · Autorentool für Content Creator                           │
│   · Bot-Chat-Widget (Onboarding + Begleitung)                 │
└───────────────┬──────────────────────────────────────────────┘
                │ API
┌───────────────▼──────────────────────────────────────────────┐
│  Corteza Backend (Compose-Module + eigene Logik)              │
│   · Module: Course, Sequence, Question, Progress, ...         │
│   · Tracking-Service (Fortschritt, Score-Berechnung)          │
│   · Content Delivery Framework (Auslieferung, Berechtigung)   │
└───────┬───────────────────────────────────┬──────────────────┘
        │                                    │
┌───────▼─────────┐              ┌───────────▼──────────────────┐
│  Video-Storage   │              │  KI-Layer (AA-Bot)           │
│  (Asset/Embed)   │              │   · Empfehlungs-Engine       │
└──────────────────┘              │   · Claude-Anbindung (API)   │
                                  │   · Kontext: Metadaten,Score │
                                  └──────────────────────────────┘
```

**Empfehlungs-Engine – zwei Ausbaustufen:**
- **Stufe 1 (regelbasiert):** Wenn Score < X → Wiederholungssequenz; sonst
  nächste Sequenz nach definierter Reihenfolge / Voraussetzungen. Schnell, robust,
  ohne KI-Risiko – guter MVP.
- **Stufe 2 (KI-gestützt):** Claude bewertet Antworten (auch Freitext), erkennt
  Wissenslücken semantisch und schlägt aus dem Sequenz-Pool die passendste vor.
  Pre-Assessment als Dialog statt starrem Formular.

---

## 8. Vorschlag Umsetzung in Phasen (für Roadmap-Slide)

| Phase | Inhalt | Ergebnis |
|---|---|---|
| **MVP** | Course/Sequence-Modell, Video-Player, Tracking, Question-Engine-Integration, **regelbasierte** Empfehlung | Lauffähige University mit linearem + einfachem adaptivem Pfad |
| **Phase 2** | KI-Pre-Assessment-Dialog, KI-gestützte adaptive Empfehlung, Score-Reporting für Manager | „Intelligente" University |
| **Phase 3** | Marketplace-Listing, Content Delivery Framework (Mandanten-Auslieferung, Versionierung, Lizenzierung), Zertifikate | Skalierbares Content-Ökosystem |

> Für die Vorstellung: MVP zeigt Machbarkeit, Phase 2 ist der „Wow"-Faktor (KI),
> Phase 3 ist die Geschäftsmodell-Vision (Marketplace).

---

## 9. Offene Punkte / Entscheidungsbedarf

1. **Video-Hosting:** Eigener Asset-Storage oder Einbettung (Vimeo/YouTube/intern)?
   → beeinflusst Tracking-Genauigkeit (% gesehen) und Datenschutz.
2. **KI-Tiefe im MVP:** Reicht regelbasierte Empfehlung zum Start, oder muss die
   KI schon in der ersten Vorstellung sichtbar sein (Demo-Effekt)?
3. **Marketplace-Scope:** Nur interne Inhaltsverteilung oder echter Marktplatz
   mit externen Anbietern & Lizenzmodell?
4. **Compliance/Zertifikate:** Werden Nachweise (z.B. Pflichtschulungen) benötigt?
5. **Wiederverwendung Question-Engine:** Welche Fragetypen unterstützt sie heute,
   welche fehlen für den Lernkontext (z.B. KI-bewerteter Freitext)?

---

## 10. Nächste Schritte (Vorschlag)

1. Konzept in der Vorstellung diskutieren, offene Punkte (Kap. 9) entscheiden.
2. Scope für MVP festziehen (welche Phase-1-Features sind „must").
3. Datenmodell (Kap. 6) als konkrete Corteza-Module spezifizieren.
4. Vorhandene Question-Engine evaluieren (Schnittstellen, Fragetypen).
5. KI-Anbindung (Claude) für Empfehlung & Pre-Assessment als Spike prototypen.
