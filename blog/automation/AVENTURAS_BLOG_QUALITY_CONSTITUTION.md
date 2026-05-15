# Aventuras Villas Blog Quality Constitution

**Purpose:**
Make the current blog quality standard permanent across every Aventuras Villas article, cron run, rewrite, approval, and publishing action.

**Core Rule:**
No Aventuras Villas article can be drafted, approved, staged, committed, pushed, or published unless it passes this constitution.

**Required Source Files Before Writing:**
1. AVENTURAS_VILLAS_FACTS_CONTRACT.md
2. Blogger Elite V5 rules
3. Current article goal
4. Confirmed public URLs only

**Mandatory Workflow:**
1. Load Facts Contract.
2. Identify article type:
 - villa rental
 - buyer/investor
 - planning
 - booking
 - support
3. Generate draft.
4. Run Blogger Elite V5 QA.
5. Run AI-language QA.
6. Run fake-claims QA.
7. Run URL/CTA QA.
8. Send full draft to Telegram.
9. Wait for founder approval.
10. Publish only after approval.
11. Stage only approved content files.
12. Commit only staged approved files.
13. Push.
14. Verify live URL returns 200.
15. Confirm automation files were not committed.

**Automatic Fail Rules:**
FAIL if article:
- uses placeholders
- uses fake URLs
- invents villa facts
- uses unsupported ROI claims
- uses appreciation promises
- uses rental yield claims unless verified
- uses AI-sounding phrases
- uses generic luxury filler
- assigns facts to the wrong villa
- treats Villa Tikal as a rental villa
- says oceanfront unless confirmed
- mentions services not confirmed
- gives only a file path instead of full draft
- says published before public URL returns 200
- stages automation files during a content publish
- publishes without founder approval

**Banned Language:**
- unlock
- perfect escape
- discerning traveler
- unparalleled
- magical
- sanctuary
- nestled
- vibrant
- hidden gem
- dream destination
- world-class
- seamless
- robust
- idyllic
- captivating
- not to be missed
- your gateway
- elevate your stay
- indulge
- luxurious retreat
- unforgettable experience
- generic travel-blog language
- generic real estate hype

**Required Voice:**
Plain-spoken.
Useful.
Specific.
Human.
Grounded.
Practical.
Lightly aspirational only when supported by facts.
No corporate polish.
No fake emotion.

**Facts Contract Rule:**
Every article must use AVENTURAS_VILLAS_FACTS_CONTRACT.md before writing.

If the contract is missing or unreadable:
QA RESULT: fail
publish status: blocked
blocker: yes

**Known Public URLs Only:**
- Blog: https://onrelas.github.io/aventurasvillas/blog/
- Direct booking: https://aventurasvillas.com/
- Buyer ecosystem: https://onrelas.github.io/aventurasvillas/
- Linktree: https://linktr.ee/aventurasvillastulum
- WhatsApp: https://wa.me/16478346090

No invented URLs.

**Cron-Specific Rules:**
Tuesday rental cron must:
- load Facts Contract
- focus on Casa Aventura and Villa Sorella
- use direct booking funnel
- not treat Villa Tikal as a rental villa

Friday buyer/investment cron must:
- load Facts Contract
- use buyer/investor funnel
- include Tulum, Riviera Maya, Aldea Zama, Casa Aventura, Villa Sorella, Villa Tikal where relevant
- include due diligence, fideicomiso, risks, property management reality
- avoid financial promises

**Publishing Rules:**
Before commit, always return staged files.
Only approved content files may be staged.
Automation files must not be staged unless the founder explicitly approves an automation commit.

**Required Pre-Publish Response:**
- QA pass yes/no
- full draft shown in Telegram yes/no
- founder approved yes/no
- staged files
- automation files staged yes/no
- blocker yes/no

**Required Post-Publish Response:**
- committed yes/no
- commit hash
- pushed yes/no
- live URL
- live URL verified 200 yes/no
- index shows article yes/no, if index was changed
- automation files not committed yes/no
- blocker yes/no