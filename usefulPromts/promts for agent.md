NOTES
- Path artık: Repo/.copilot-conversion/promts/
- Klasör adı "promts" (typo korunuyor)
- Her uzun iş checkpoint'lere bölünüyor → "continue" yazana kadar agent durur
- Pahalı semantic search yerine önce keyword/grep
- Yeni prompts: prompt-07-glossary-search.md, prompt-08-verify-conversion.md
- Phase 4 artık iki pass: önce iskeletler (Pass A), sonra body'ler (Pass B)
- Phase 6 eklendi: Java implementation vs COBOL karşılaştırma

MODEL ÖNERİSİ
- Haiku 4.5     → Phase 0 scan, Phase 1 Pass A (manifest/grep), Phase 4 Pass A (skeletons), Phase 7 (glossary)
- Sonnet 4.6    → Phase 1 Pass B, Phase 2, Phase 5 tests
- Opus 4.6/4.7  → Phase 3 (mapping), Phase 4 Pass B (impl), Phase 6 (verify)


=========================================================================
Session 0 => one-time per project
=========================================================================

C0. Yapıştırmadan önce kontrol et:
- .gitignore içinde "Repo/.copilot-conversion/STATE/" satırı var mı?

promt:
Read these two files and follow them:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-01-scan-repo.md

After reading prompt-00 reply only "READY. Awaiting phase prompt." and stop.
Then I will say "proceed".

Do not commit, do not push, do not run any git commands.

-------------

+ New Chat → Agent → Haiku 4.5 (veya Sonnet 4.6)
  "READY" → proceed
  Agent kısa reconnaissance yapar (build tool, Java version, root package)
  Soru sorar varsa cevapla
  STATE/repo-scan-plan.md üretir → durur
  → "continue" yaz → agent 3 dosya analiz eder → STATE/repo-scan-checkpoint-01.md üretir → durur
  → "continue" yaz → CP-02 → durur → "continue" → CP-03 → ...
  Tüm checkpoint'ler bittiğinde:
  → "synthesize" yaz → STATE/repo-profile.md üretilir
  repo-profile.md'yi AÇ ve OKU. Canonical examples bölümü kritik.
  Yanlış varsa düzelt. Chat'i kapat.


=========================================================================
Session 1'e başlamadan önce
=========================================================================

C1. COBOL dosyasını şuraya koy:
Repo/.copilot-conversion/inbox/COBOL.CBL


=========================================================================
session 1 — Intake + LOC check + Pass A (Manifest)
=========================================================================

promt:
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-02-analyze-cobol.md
3. Repo/.copilot-conversion/STATE/repo-profile.md

After prompt-00 reply only "READY. Awaiting phase prompt." and stop.
Then I will say "proceed".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Haiku 4.5
  "READY" → proceed
  Agent intake soruları sorar (4 numaralı). Cevap örnekleri:

  FULL:
    1. Path: Repo/.copilot-conversion/inbox/COBOL.CBL
    2. Mode: FULL
    3. (atla)

  PARTIAL by paragraf adı:
    1. Path: Repo/.copilot-conversion/inbox/COBOL.CBL
    2. Mode: PARTIAL
    3. (a) Paragraph names: CALC-TAX, CALC-NET-PAY

  PARTIAL by keyword:
    1. Path: Repo/.copilot-conversion/inbox/COBOL.CBL
    2. Mode: PARTIAL
    3. (b) Keywords: TAX, INTEREST, LOAN-CALC

  PARTIAL by feature:
    3. (d) Feature: "calculate the monthly interest on consumer loans"

  Agent LOC sayar → strategy önerir (SMALL/MEDIUM/LARGE) → durur
  → "continue" yaz → Pass A başlar

  SMALL/MEDIUM → tek seferde 01a-manifest.md üretilir
  LARGE → 2000-satırlık window'lara böler:
  Her window için "continue" yaz → window-NN.md üretir → durur
  Tümü bitince agent otomatik olarak birleştirir → 01a-manifest.md

  Manifest hazır. Chat'i kapatabilirsin.


=========================================================================
session 1.5 — (sadece PARTIAL by keyword/field/feature için)
=========================================================================

promt:
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-02-analyze-cobol.md
3. Repo/.copilot-conversion/STATE/repo-profile.md
4. Repo/.copilot-conversion/STATE/conversions/COBOL/01a-manifest.md

After prompt-00 reply only "READY." and stop.
Then I will say "partial-search TAX INTEREST LOAN-CALC".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Sonnet 4.6
  "READY" → "partial-search TAX INTEREST LOAN-CALC"
  Agent keyword'lerle grep yapar, candidate paragraph tablosu sunar
  Sana sorar: "Hangi paragraflar scope'a girsin?"
  Cevapla: "Paragraphs 1, 3, 5, 7. Also include CALC-HELPER called by paragraph 3."
  Agent 01a-scope.md üretir → durur
  → "continue" yaz → 01a-slice-plan.md üretir (slice grupları)
  Chat'i kapat.


=========================================================================
session 2..N — Pass B (Per-Slice Semantic Analysis)
=========================================================================

NOT: Her slice için YENİ CHAT aç.

promt (her slice için):
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-02-analyze-cobol.md
3. Repo/.copilot-conversion/STATE/repo-profile.md
4. Repo/.copilot-conversion/STATE/conversions/COBOL/01a-manifest.md
5. Repo/.copilot-conversion/STATE/conversions/COBOL/01a-slice-plan.md

PROGRAM_NAME: COBOL

After prompt-00 reply only "READY." and stop.
Then I will say "pass-b S1".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Sonnet 4.6
  "READY" → "pass-b S1"
  Agent SADECE S1'in line range'lerini okur (tüm COBOL'u değil!)
  01b-analysis-S1.md üretilir
  Sorular varsa cevapla → chat'i kapat
  → Yeni chat → aynı promtla başla → "pass-b S2" → ...
  Tüm slice'lar analiz edilince session 3'e geç.


=========================================================================
session N+1..2N — Phase 2: Business Rules (her slice için)
=========================================================================

promt (her slice için):
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-03-extract-rules.md
3. Repo/.copilot-conversion/STATE/repo-profile.md
4. Repo/.copilot-conversion/STATE/conversions/COBOL/01a-manifest.md
5. Repo/.copilot-conversion/STATE/conversions/COBOL/01b-analysis-S1.md

PROGRAM_NAME: COBOL

After prompt-00 reply only "READY." and stop.
Then I will say "Extract rules for slice S1".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Sonnet 4.6
  "READY" → "Extract rules for slice S1"
  Agent BR-S1-001, BR-S1-002, ... şeklinde rule'ları üretir → 02-rules-S1.md
  Sorular varsa cevapla
  Kuralları oku → eksik var mı?
  Chat'i kapat → yeni chat → S2 için tekrar et.


=========================================================================
session 2N+1 — Phase 3: Mapping Plan (TEK seans)
=========================================================================

promt:
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-04-plan-mapping.md
3. Repo/.copilot-conversion/STATE/repo-profile.md
4. Repo/.copilot-conversion/STATE/conversions/COBOL/01a-manifest.md
5. All Repo/.copilot-conversion/STATE/conversions/COBOL/02-rules-*.md

PROGRAM_NAME: COBOL

After prompt-00 reply only "READY." and stop.
Then I will say "proceed".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Opus 4.6 (veya 4.7 — kritik faz, kaliteli model kullan)
  "READY" → proceed
  Agent 03-mapping.md üretir + implementation batch listesi (B1, B2, B3, ...)
  Mapping'i DİKKATLE oku — yanlış mapping → yanlış kod
  Beğenmediğin yer: "BR-S1-003 should go to TaxService not PayrollService"
  Beğendin → chat'i kapat.


=========================================================================
session 2N+2 — Phase 4 Pass A: Skeleton Plan
=========================================================================

promt:
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-05-implement.md
3. Repo/.copilot-conversion/STATE/repo-profile.md
4. Repo/.copilot-conversion/STATE/conversions/COBOL/03-mapping.md

After prompt-00 reply only "READY." and stop.
Then I will say "pass-a-plan".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Haiku 4.5 (iskelet işi, ucuz model yeter)
  "READY" → "pass-a-plan"
  Agent 04a-skeleton-plan.md üretir (CP-01, CP-02, ... her biri 3-4 dosya)
  → durur
  Aynı chat'te devam edebilirsin VEYA yeni chat aç (önerim: yeni chat):

  → "skeleton CP-01" yaz → 3-4 boş dosya (TODO body'lerle) oluşur
  → her dosya için Accept
  → durur
  → "skeleton CP-02" yaz → ... (veya yeni chat aç)
  Tüm CP'ler bitince 04a-skeleton-log.md dolar.


=========================================================================
session 2N+3+ — Phase 4 Pass B: Implementation (her batch yeni chat)
=========================================================================

İLK promt (Pass B planı için):
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-05-implement.md
3. Repo/.copilot-conversion/STATE/repo-profile.md
4. Repo/.copilot-conversion/STATE/conversions/COBOL/03-mapping.md
5. Repo/.copilot-conversion/STATE/conversions/COBOL/04a-skeleton-log.md

After prompt-00 reply only "READY." and stop.
Then I will say "pass-b-plan".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Sonnet 4.6
  "READY" → "pass-b-plan"
  04b-impl-plan.md üretilir (CP-01, CP-02, ... her biri 2-3 dosya)
  Chat'i kapat.


HER IMPL CP İÇİN YENİ CHAT (kritik, context küçük kalır):

promt:
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-05-implement.md
3. Repo/.copilot-conversion/STATE/repo-profile.md
4. Repo/.copilot-conversion/STATE/conversions/COBOL/03-mapping.md
5. Repo/.copilot-conversion/STATE/conversions/COBOL/04b-impl-plan.md

After prompt-00 reply only "READY." and stop.
Then I will say "impl CP-01".

Do not commit, do not push, do not run git. Do not run mvn/gradle without asking.
----

+ New Chat → Agent → Opus 4.6 (business logic en pahalı/önemli faz)
  "READY" → "impl CP-01"
  Agent 2-3 dosyayı tek tek implement eder
  Her dosya için IntelliJ Accept/Reject
  Agent mvn çalıştırmak isterse: sen karar ver
  04b-impl-log.md güncellenir
  Chat'i kapat → Yeni chat → "impl CP-02" → ...


=========================================================================
session sonu — Phase 5: Tests (her batch yeni chat)
=========================================================================

promt:
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-06-generate-tests.md
3. Repo/.copilot-conversion/STATE/repo-profile.md
4. Repo/.copilot-conversion/STATE/conversions/COBOL/04b-impl-log.md

PROGRAM_NAME: COBOL

After prompt-00 reply only "READY." and stop.
Then I will say "Run Phase 5 for batch B1".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Sonnet 4.6
  "READY" → "Run Phase 5 for batch B1"
  Test dosyaları üretilir → 05-test-log-B1.md
  Coverage matrisi gösterir: "BR-S1-003 → TaxServiceTest.shouldApplyHigherTaxBracket_BR_S1_003()"
  Chat'i kapat → yeni chat → B2 → ...


=========================================================================
Phase 6 — Verification (YENI! COBOL vs Java karşılaştırması)
=========================================================================

İLK promt (verify planı):
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-08-verify-conversion.md
3. Repo/.copilot-conversion/STATE/repo-profile.md
4. Repo/.copilot-conversion/STATE/conversions/COBOL/03-mapping.md
5. All Repo/.copilot-conversion/STATE/conversions/COBOL/02-rules-*.md
6. Repo/.copilot-conversion/STATE/conversions/COBOL/04b-impl-log.md

After prompt-00 reply only "READY." and stop.
Then I will say "verify-plan".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Opus 4.6
  "READY" → "verify-plan"
  06-verify-plan.md üretilir (CP-01, CP-02, ... her biri 5 BR-ID)
  Chat'i kapat.


HER VERIFY CP İÇİN YENİ CHAT:

promt:
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-08-verify-conversion.md
3. Repo/.copilot-conversion/STATE/repo-profile.md
4. Repo/.copilot-conversion/STATE/conversions/COBOL/06-verify-plan.md

After prompt-00 reply only "READY." and stop.
Then I will say "verify CP-01".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Opus 4.6
  "READY" → "verify CP-01"
  Agent 5 BR-ID'yi tek tek doğrular (COBOL intent vs Java code)
  Tablo: BR-ID | Coverage (FULL/PARTIAL/MISSING) | Precision OK? | Notes
  06-verify-log.md güncellenir
  Chat'i kapat → yeni chat → "verify CP-02" → ...

SON CHAT (özet):
"verify-summary" → final raporu üretilir (eksik BR-ID listesi + remediation)


=========================================================================
BONUS — Phase 7: Glossary / Targeted Search (ne zaman gerekirse)
=========================================================================

Bir gün sonra "PAYROLL01'de hangi paragraf TAX-RATE'i kullanıyor?" diye
sorman gerekirse: tüm COBOL'u tekrar okuma. Bu promtu kullan.

promt:
Read:
1. Repo/.copilot-conversion/promts/prompt-00-system.md
2. Repo/.copilot-conversion/promts/prompt-07-glossary-search.md
3. Repo/.copilot-conversion/STATE/conversions/COBOL/01a-manifest.md

After prompt-00 reply only "READY." and stop.
Then I will say "Find <PATTERN> in COBOL".

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Haiku 4.5 (ucuz, hızlı)
  "READY" → "Find all COMPUTE statements involving TAX in COBOL"
  Agent manifest'ten candidate line range'leri çeker, grep yapar
  Tablo: # | Paragraph | Lines | Snippet | Notes
  Chat'i kapat.


=========================================================================
SON: Build + Commit (manuel, terminal'de)
=========================================================================

cd C:\dev\workspace\project\Repo

mvn clean test
grep -r "VERIFY" src/        # boş çıkmalı; kaldıysa düzelt

cd ..
git status                    # STATE/ GÖRÜNMEMELI
git add Repo/src/ Repo/pom.xml
git commit -m "feat: convert COBOL COBOL (PARTIAL: TAX/INTEREST) to Java"
git push


=========================================================================
TROUBLESHOOTING (sık karşılaşılanlar)
=========================================================================

- Agent timeout: COBOL'un tamamını okumaya çalışıyor demektir.
  → Phase 1 strategy'sini LARGE olarak teyit et, window'ları kullansın.

- Agent yanlış paket yolu üretiyor:
  → repo-profile.md eksik. Phase 0'ı tekrarla, özellikle "canonical
  examples" tablosunu doldurt.

- Skeleton CP fazla dosya açıyor:
  → Agent'a de: "Stop, split this CP into CP-NN-a (first 3 files)
  and CP-NN-b (rest)."

- BR-### verification'da MISSING çıktı:
  → Yeni mini Phase 4 Pass B chat aç:
  "Run a focused impl checkpoint for BR-S1-007 only.
  Open the relevant skeleton file and add the missing logic."

- Agent mvn/git çalıştırmak istiyor:
  → R3 ihlali. Reddet, "remember rule R3" hatırlat.

- Context >70% uyarısı:
  → Hemen dur. Mevcut işi state'e kaydet. Yeni chat aç.


=========================================================================
HIZLI KARAR AKIŞI
=========================================================================

Yeni proje mi?                  → Session 0 (one-time)
Yeni COBOL geldi mi?            → Session 1'den başla
COBOL çok uzun mu (>2000 LOC)?  → LARGE strategy, window'lar otomatik
Sadece bazı kurallar mı?        → PARTIAL mode, keyword search kullan
Implementation timeout aldı mı? → Yeni chat aç, CP'yi ikiye böl
Mapping yanlış mı?              → Phase 3'ü tekrarla (en kritik faz)
Eksik BR var mı?                → Phase 6 verify çalıştır, focused fix yap