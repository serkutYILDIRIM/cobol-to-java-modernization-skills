Session 0 => just one run

Read these two files and follow them:
1. .copilot-conversion/prompts/prompt-00-system.md
2. .copilot-conversion/prompts/prompt-01-scan-repo.md

After reading prompt-00 reply only "READY. Awaiting phase prompt." and stop.
Then I will say "proceed".

Do not commit, do not push, do not run any git commands.

-------------


"READY" gelir → proceed yaz
Agent reponu tarar, sorular sorabilir, cevapla
.copilot-conversion/STATE/repo-profile.md üretilir
Aç ve oku! En kritik adım. Yanlış bir şey varsa düzelt.
Chat'i kapat

session 1

then PAYROLL01.CBL file put to => .copilot-conversion/inbox/


Read:
1. .copilot-conversion/prompts/prompt-00-system.md
2. .copilot-conversion/prompts/prompt-02-analyze-cobol.md
3. .copilot-conversion/STATE/repo-profile.md

After prompt-00 reply only "READY. Awaiting phase prompt." and stop.
----

+ New Chat → Agent → Opus 4.6
  "READY" → proceed
  Agent sorar: "Hangi COBOL? FULL mu PARTIAL mı?"
  Cevapla:
  Tam dönüşüm: FULL. Read the COBOL from .copilot-conversion/inbox/PAYROLL01.CBL
  Kısmi: PARTIAL. Convert only paragraphs CALC-TAX and CALC-NET-PAY. Read from .copilot-conversion/inbox/PAYROLL01.CBL
  Agent analiz eder, STATE/conversions/PAYROLL01/01-analysis.md yazar
  Sorular varsa cevapla
  Analizi oku. Doğru mu? Eksik var mı?
  Chat'i kapat.


session 2

Read:
1. .copilot-conversion/prompts/prompt-00-system.md
2. .copilot-conversion/prompts/prompt-03-extract-rules.md
3. .copilot-conversion/STATE/repo-profile.md
4. All files in .copilot-conversion/STATE/conversions/PAYROLL01/

PROGRAM_NAME for this session is: PAYROLL01

After prompt-00 reply only "READY." and stop.

Do not commit, do not push, do not run git.
-----


+ New Chat → Agent → Opus 4.6

  "READY" → proceed
  Agent BR-001, BR-002, ... şeklinde kuralları çıkarır, 02-rules.md yazar
  Sorular varsa cevapla
  Kuralları oku — tüm iş kuralları yakalanmış mı?
  Chat'i kapat.


session 3

Read:
1. .copilot-conversion/prompts/prompt-00-system.md
2. .copilot-conversion/prompts/prompt-04-plan-mapping.md
3. .copilot-conversion/STATE/repo-profile.md
4. All files in .copilot-conversion/STATE/conversions/PAYROLL01/

PROGRAM_NAME for this session is: PAYROLL01

After prompt-00 reply only "READY." and stop.

Do not commit, do not push, do not run git.
------------

+ New Chat → Agent → Opus 4.6
  Yapıştır (sadece prompt-04 değişir, geri kalan aynı):
  proceed → agent plan üretir, kod yazmaz
  03-mapping.md yazar: "şu sınıflar şu paketlerde, BR-001 şu metoda gidecek"
  Bu planı dikkatle oku — en kritik kontrol noktası. Yanlış mapping → yanlış kod.
  Beğenmediğin yer varsa: chat'te "BR-003 should go to TaxService not PayrollService, please update the plan" de
  Beğendin → onayla → chat'i kapat


session 4

Read:
1. .copilot-conversion/prompts/prompt-00-system.md
2. .copilot-conversion/prompts/prompt-05-implement.md
3. .copilot-conversion/STATE/repo-profile.md
4. All files in .copilot-conversion/STATE/conversions/PAYROLL01/

PROGRAM_NAME for this session is: PAYROLL01.
The Phase 3 plan has been approved.

After prompt-00 reply only "READY." and stop.

Do not commit, do not push, do not run git. Do not run mvn/gradle
without asking first.
--------

+ New Chat → Agent → Opus 4.6 (kod kalitesi için 4.7 da seçebilirsin)
  proceed → agent dosyaları tek tek üretir
  IntelliJ her dosya için Accept/Reject sorar — kontrol et, kabul et
  Agent terminal komutu çalıştırmak isterse (mvn compile gibi) → dur, sor: "build çalıştırabilir miyim?" — sen karar ver
  04-implementation-log.md güncellenir
  Agent bitince listesi verir: "X dosya oluşturuldu, Y rule implement edildi"
  Chat'i kapat.

session 5

Read:
1. .copilot-conversion/prompts/prompt-00-system.md
2. .copilot-conversion/prompts/prompt-06-generate-tests.md
3. .copilot-conversion/STATE/repo-profile.md
4. All files in .copilot-conversion/STATE/conversions/PAYROLL01/

PROGRAM_NAME for this session is: PAYROLL01

After prompt-00 reply only "READY." and stop.

Do not commit, do not push, do not run git.
----

+ New Chat → Agent → Opus 4.6
+ proceed → agent testleri üretir
  Coverage matrisi verir: "BR-001 → PayrollServiceTest.shouldCalculateGrossPay()"
  Tüm kurallar test edilmiş mi kontrol et


