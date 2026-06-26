# Registrierungs-Fragebögen — Theme „Content" (AA University)

> **Status:** Spezifikation für Question-Engine
> **Stand:** 2026-06-26
> **Bezug:** `aa-university-content-delivery-konzept.md` (Kap. 5.4, Schritt 1 der User Journey)
> **Maschinenlesbar:** `data/aa-university-questionnaires.json`

Dieses Dokument definiert die Fragebögen, die es für das Theme **Content** noch
nicht gab. Es sind **Registrierungs-/Onboarding-Fragebögen**, die *vor* der
Inhaltsauswahl ausgefüllt werden und die KI-gestützte Lernpfad-Empfehlung
speisen.

Zwei Fragebögen:

1. **`content_learner_onboarding`** — Eingangs-Assessment für Lernende
   (Vorwissen, Ziele, Erwartung, Lernpräferenzen + optionaler Wissens-Check).
2. **`content_creator_registration`** — Registrierung als Content-Ersteller
   (Expertise, Inhaltstypen, Zielgruppe).

---

## Feld-Konventionen (für die Question-Engine)

| Attribut | Bedeutung |
|---|---|
| `key` | eindeutiger technischer Schlüssel |
| `type` | `single_choice` · `multiple_choice` · `likert_1_5` · `free_text` · `number` |
| `required` | Pflichtfeld ja/nein |
| `ai_context` | Antwort wird dem KI-Bot als Kontext für die Empfehlung übergeben |
| `scoring` | wenn gesetzt: Frage geht in objektiven Score ein (Punkte je Antwort) |
| `skill_tag` | ordnet die Frage einem Skill/Themenbereich zu (für Gap-Analyse) |

---

## Fragebogen 1 — `content_learner_onboarding`

**Titel:** „Willkommen in der AA University – lass uns deinen Lernpfad finden"
**Typ:** registration / pre-assessment
**Ausgelöst:** beim ersten Betreten der University bzw. eines neuen Themas.

### Abschnitt A — Rolle & Kontext
| Key | Frage | Typ | Pflicht | Optionen |
|---|---|---|---|---|
| `role` | In welchem Bereich arbeitest du hauptsächlich? | single_choice | ja | Vertrieb · Marketing · Support/Service · Management · IT/Admin · Sonstiges |
| `crm_tenure` | Wie lange arbeitest du schon mit dem CRM? | single_choice | ja | Neu (< 3 Monate) · 3–12 Monate · > 1 Jahr · Power-User |
| `goal_context` | Gibt es einen konkreten Anlass für deine Weiterbildung? | free_text | nein | – |

### Abschnitt B — Selbsteinschätzung Vorwissen (Likert 1–5, `ai_context`, `skill_tag`)
| Key | Themenbereich (skill_tag) |
|---|---|
| `skill_basics` | CRM-Grundlagen / Navigation |
| `skill_contacts` | Kontakte & Leads |
| `skill_pipeline` | Pipeline & Deals |
| `skill_reporting` | Auswertungen & Reporting |
| `skill_automation` | Automationen / Workflows |
| `skill_ai` | KI-Funktionen im CRM |

> Skala: 1 = „noch nie gemacht" … 5 = „kann ich anderen beibringen".

### Abschnitt C — Lernziele & Erwartung
| Key | Frage | Typ | Pflicht | Optionen |
|---|---|---|---|---|
| `learning_goals` | Was möchtest du erreichen? (Mehrfachauswahl) | multiple_choice | ja | Grundlagen sicher beherrschen · Effizienter arbeiten · Neue Funktionen kennenlernen · Auf Zertifizierung vorbereiten · Team schulen · Sonstiges |
| `expectation` | Was erwartest du dir konkret von der University? | free_text | nein | – |

### Abschnitt D — Lernpräferenzen
| Key | Frage | Typ | Pflicht | Optionen |
|---|---|---|---|---|
| `time_budget` | Wie viel Zeit pro Woche möchtest du investieren? | single_choice | ja | < 30 Min · 30–60 Min · 1–2 Std · > 2 Std |
| `format_pref` | Bevorzugtes Lernformat | single_choice | nein | Kurze Häppchen · Längere zusammenhängende Einheiten · Egal |

### Abschnitt E — Optionaler Wissens-Check (objektives Scoring)
> Kurze Fachfragen zur *objektiven* Einstufung — ergänzt die Selbsteinschätzung.
> Jede Frage trägt `scoring` und `skill_tag`. Optional überspringbar.

| Key | skill_tag | Punkte (max) |
|---|---|---|
| `check_basics_1` | skill_basics | 1 |
| `check_pipeline_1` | skill_pipeline | 1 |
| `check_reporting_1` | skill_reporting | 1 |

(Konkrete Fragetexte/Antworten siehe JSON.)

### → Auswertung / Übergabe an KI
Aus Abschnitt B (Selbsteinschätzung), C (Ziele) und E (Score) erstellt der
AA-Bot ein **Lernprofil** und schlägt den initialen Lernpfad vor. Niedrige
Selbsteinschätzung *oder* niedriger Check-Score bei einem `skill_tag` →
Grundlagen-Sequenzen zuerst.

---

## Fragebogen 2 — `content_creator_registration`

**Titel:** „Werde Content-Ersteller in der AA University"
**Typ:** registration
**Ausgelöst:** wenn ein Nutzer Inhalte erstellen / im Marketplace anbieten möchte.

| Key | Frage | Typ | Pflicht | Optionen |
|---|---|---|---|---|
| `expertise_areas` | In welchen Themen möchtest du Inhalte erstellen? | multiple_choice | ja | CRM-Grundlagen · Vertrieb · Marketing · Support · Reporting · Automation · KI · Sonstiges |
| `content_types` | Welche Inhaltsformate planst du? | multiple_choice | ja | Video-Sequenzen · Wissensartikel · Quiz/Fragen · Templates · Sonstiges |
| `target_audience` | Für welche Zielgruppe? | multiple_choice | ja | Einsteiger · Fortgeschrittene · Power-User · Admins · Manager |
| `experience` | Hast du schon Schulungs-/Trainingserfahrung? | single_choice | nein | Ja, umfangreich · Etwas · Nein |
| `marketplace_intent` | Möchtest du Inhalte im Marketplace anbieten? | single_choice | ja | Nur intern · Intern + extern · Noch unklar |
| `motivation` | Kurz: Was möchtest du vermitteln? | free_text | nein | – |

---

## Offene Punkte
1. **Fachfragen Abschnitt E:** Texte/Antworten sind Platzhalter — fachlich
   final abnehmen lassen.
2. **Skill-Taxonomie:** `skill_tag`-Liste sollte mit der Kurs-/Sequenz-Metadatik
   (Kap. 6 Konzept) identisch sein, damit die Gap-Analyse greift.
3. **Re-Assessment:** Soll der Fragebogen periodisch erneut angeboten werden
   (Fortschrittsmessung über Zeit)?
