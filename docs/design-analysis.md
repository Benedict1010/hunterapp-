# AI Job Hunter — design analysis

## 1. Existing project analysis

- Flutter project `hunter`, Dart SDK constraint `^3.12.2`.
- Current implementation is the untouched Flutter counter template in `lib/main.dart`; it has no product UI, routing, state layer, assets, backend integration, authentication, or data persistence.
- `pubspec.yaml` contains only Flutter, `cupertino_icons`, `flutter_test`, and `flutter_lints`.
- Visual source: `design/visily-multiscreens (1).pdf` and `(2).pdf`. They are image-based, so this analysis is based on visual inspection rather than PDF text extraction.
- Source count discrepancy: each supplied PDF has seven pages/screens, for **14 visible screens total**, despite the brief stating 16. Screens 15–16 cannot be analyzed from the files supplied. They are listed below as missing rather than invented.

## 2. Screen inventory and screen-by-screen UI analysis

All shown screens use a tall mobile canvas, very pale cool-gray background, thin light-gray separators, black/dark-charcoal display headings, bright blue primary controls, rounded cards, and a 9:41 status bar. Screens 2–7 share the `AI Job Hunter` wordmark header (blue rounded-square briefcase icon and bell) and the Home / Jobs / Applications / Profile tab bar. Screens 8–14 use Optimize / Jobs / Alerts / Profile; this is a visible navigation inconsistency, not a resolved product decision.

### 1. Landing / onboarding

- **Purpose:** introduce AI Job Hunter and start or sign in.
- **Sections and copy:** brand header; large AI/job-search illustration with `98% AI Match`; pills `PRIVACY GUARANTEED` and `AI-POWERED`; headline `Your AI Job Search, Automated.`; supporting copy; benefits card: `Hyper-Personalized Matching` and `AI Resume Tailoring` with descriptions.
- **Actions/navigation:** blue `Get Started` button with arrow; `Sign In` text link with chevron. Destinations are not shown.
- **Layout/style:** 24-ish px outer padding; image is wide and square-cornered; benefit rows have pale-blue icon tiles and divider; blue gradient/solid primary button, rounded about 14 px, soft shadow. `Automated.` is blue italic serif; main heading is large bold serif.
- **Ambiguity:** the illustration content and whether it is a bundled or remote asset are not specified.

### 2. Resume Verified / profile setup step 2

- **Purpose:** confirm resume analysis before selecting sources.
- **Visible UI:** header/bell; resume-success illustration; `Resume Verified`; subtitle; large resume-summary card with filename `Benedict_Joseph_Resume`, success status, refresh icon and `Replace`; extracted skills chips (React, JavaScript, TypeScript, TailwindCSS, Node.js, Python, UI/UX Design); professional experience; academic background; blue-tinted `AI SUMMARY` quote.
- **Actions:** `Replace`; primary `Continue to Job Sources`; light tip row about project keywords with chevron; profile tab selected.
- **States:** successful analysis; progress label `Step 2 of 4: Profile Setup`.

### 3. Choose Job Sources / setup step 2 of 4

- **Purpose:** choose job platforms for scanning.
- **Visible UI:** step marker; `Choose Job Sources`; Smart Scanning Enabled info callout; `AVAILABLE PLATFORMS` and `2 Selected`; two-column platform cards. LinkedIn and Unstop selected/on with `TOP MATCH` ribbons and `Active Sync`; Naukri, Internshala, Indeed and Career Pages off with `Discovery` labels; `+ Add Custom Domain` outlined control.
- **Actions:** platform switches; add domain; primary `Continue`; bottom tabs with Jobs selected.
- **Layout/style:** 16-ish px gutters, 2-column cards, blue selected switches/ribbons, card borders and slight shadows; footnote says sources can be changed later in Settings.
- **Ambiguity:** platform authorization, custom-domain validation, selected source persistence, and the intended next setup screen are not shown.

### 4. Set Your Pace / job preferences

- **Purpose:** set role, job type, mode, compensation, location, and match threshold.
- **Visible UI:** role chips (Product Designer and Frontend Engineer selected; Backend Dev, Fullstack, Data Scientist, DevOps, Mobile Developer; `+ Custom`); three job-type tiles (Full-time selected); three work-mode tiles (Remote selected); monthly salary slider `₹25,000`, range cap `₹50,000+`, endpoints `₹10K`/`₹50K`; removable location chips Bangalore, Mumbai, Remote; `Add another city...` input; AI confidence card `85% Minimum Match` plus slider.
- **Actions:** select/toggle chips and tiles, salary and threshold sliders, remove/add location, `Save Preferences`; Profile tab selected.
- **Ambiguity:** currency/range semantics, chip multi-select rules, custom role/location behavior, and slider stepping are not visible.

### 5. Home / active search dashboard

- **Purpose:** show search status, metrics, and a recommended job.
- **Visible UI:** greeting `Good morning, Benedict`; active-search card `AI JOB SEARCH ACTIVE`, `Intelligent Hunting...`, source description, brain image, `Manage Search`, info icon; four metric tiles: Jobs Scanned 1,284; New Matches 42; Strong Matches 18; Applications 08; dark `TOP MATCH READY` card for `Senior Product Designer at Google Cloud`; profile-completion prompt.
- **Actions:** Manage Search, information icon, `View All`, `Review & Apply Now`, completion row chevron; Home tab selected.
- **States:** search active; metric trend pills; top match ready.

### 6. Jobs For You / match list

- **Purpose:** browse AI-curated job matches.
- **Visible UI:** title/subtitle; search input `Search job titles or companies...`; filters icon; horizontal chips (All Matches selected, Design, Remote, partially visible `Over $12…`); `3 PREMIUM MATCHES FOUND`; `Sort by: Match %`; three job cards (Senior Product…/TechCorp/98%; Creative UI/DesignStudio/92%; Data/DataSolutions/88%) each with logo, bookmark, location, compensation, `WHY IT MATCHES` rationale, tag chips, and `View Job`.
- **Actions:** search, filters, filter chips, sort, bookmark, view job, `Edit Preferences`; Jobs tab selected.
- **Ambiguity:** the truncated fourth filter label, filter/sort menus, pagination, and bookmark state behavior are not shown.

### 7. Job detail / Software Engineer Intern

- **Purpose:** evaluate a job and tailor/apply.
- **Visible UI:** company image; title `Software Engineer Intern`; ABC Technologies and age; location/Hybrid/salary chips; `AI Skill Analysis 94% Match` score bar and quote; About the Role; requirements checklist; Skills Match tiles (React 95%, TypeScript 90%, UI/UX Design 85%, Node.js 80%); improvement-area rows (GraphQL Low impact, Docker Learnable).
- **Actions:** `Tailor Resume`, `Apply Now`, share, bookmark; Jobs tab selected.
- **States:** strong match, top skills, improvement areas, application closing in 5 days.
- **Ambiguity:** apply target, save state, and whether tailoring is available without an uploaded resume are not defined.

### 8. Resume Optimization Ready

- **Purpose:** report a tailored-resume improvement.
- **Visible UI:** `RESUME OPTIMIZATION`; illustration; tailored-for role, `Optimized` badge, score comparison Previous 78% / New Score 94%, 16% improvement notice; source-file row; four Key Improvements cards (Action-Oriented Verbs, Skill Alignment, Quantified Achievements, ATS Keyword Optimization) with impact pills; quote.
- **Actions:** Change source file, `Review Tailored Resume`, `Download PDF`, `Apply Now`; Optimize tab selected.
- **Ambiguity:** download destination/file permissions and Apply Now behavior are not shown.

### 9. Tailored Resume preview

- **Purpose:** preview, edit, or export the optimized resume.
- **Visible UI:** back/title `Tailored Resume`, subtitle `Software Engineer Role`, share; AI optimization callout (94%); `VERSION 2.4 • UPDATED JUST NOW`; document-preview panel with zoom controls, 85%, `Edit`, `Export`, page indicator `PAGE 1 OF 2`; recent changes rows (Skills Alignment, Summary Refinement); floating download button.
- **Actions:** back, share, zoom, Edit, Export, View All, rows, download FAB; Optimize tab selected.
- **Ambiguity:** document rendering/editor scope, export formats, version history, and recent-change detail are not specified.

### 10. Applications list

- **Purpose:** list tracked applications by status.
- **Visible UI:** `Applications`; filter icon; search input; tabs Applied (selected), Interviewing, Offered, each count 1; `1 JOBS FOUND`, `Newest first`; one ABC Technologies card with `Senior Software Eng…`, 94% Match, San Francisco, Oct 24 2023, Applied status and `View Details`; match-score callout; add FAB.
- **Actions:** filter, search, status tabs, sorting, View Details, add application; Jobs tab selected despite this being the applications screen.
- **Ambiguity:** whether the FAB creates manual applications and why the Jobs rather than Applications tab is active.

### 11. Application Details / hiring process

- **Purpose:** track a specific application and external employer portal.
- **Visible UI:** back button; illustration with process stages; title pill `Application Details`; job summary card (Full-time, Senior Frontend Engineer, TechFlow Systems, remote location, Oct 12 2023, overflow menu); vertical timeline: Application Received, Resume Screened, Technical Assessment complete, Technical Interview scheduled, Final Round Panel TBD; External Tracking card; update timestamp.
- **Actions:** back, overflow, external-tracking icon, `Track on Portal`; Jobs tab selected.
- **States:** first three timeline stages complete; interview current/active; final round pending.
- **Ambiguity:** portal integration, editable status/notes, and overflow actions are not visible.

### 12. Notifications

- **Purpose:** show career-assistant updates.
- **Visible UI:** `Notifications`, `CAREER ASSISTANT UPDATES`, filter and mark-read/check icons; All Alerts selected / Unread with blue dot; recent activity feed cards: High Match Found!, Resume Optimized, Application Viewed, New Opportunity, Weekly Insights Ready; timestamps, overflow menus, in-card CTA links; blue `AI Pro Tip` banner; seven-day footer.
- **Actions:** filter, mark read, tabs, each CTA/overflow, pro-tip chevron; Alerts tab selected.
- **States:** visually emphasized/unread first two cards; muted read cards; unread badge.
- **Ambiguity:** filtering, read-state persistence, and notification settings behavior are not specified.

### 13. Account Profile

- **Purpose:** view account and app preferences.
- **Visible UI:** title/gear; avatar with edit-camera badge; `Alex Rivera`, email, Developer badge; AI provider radio cards Lumina GPT-4o (selected, `Premium Active`, Best for Resumes) and Claude 3.5 Sonnet; management rows (Personal Information, Job Preferences, App Language); preferences (Push Notifications on, Auto-Optimization off, Security & Privacy); sign out; version text.
- **Actions:** gear, avatar edit, provider selection, rows, toggles, Sign Out; Profile tab selected.
- **Ambiguity:** provider names/availability, premium entitlement, account editing, and sign-out confirmation are not defined.

### 14. Settings

- **Purpose:** detailed AI, search/alerts, and privacy settings.
- **Visible UI:** `Settings`, info icon; profile summary with Edit; AI Career Intelligence: Smart AI Tailoring on, Real-time Suggestions off, Target Role Preferences with `SOFTWARE ENGINEER`; Job Search & Alerts: Smart Job Alerts on, Remote Work Only `ENABLED`, Preferred Salary Range `$120K+`; data-security illustration/copy; Privacy Controls: Public Profile on, Share Usage Data on, Communication Preferences; Help & Support, Log Out, version text.
- **Actions:** info, Edit, toggle settings, chevron rows, Help & Support, Log Out; Profile tab selected.
- **Ambiguity:** Settings vs Account Profile ownership/route relationship, currency conflict with screen 4, and all privacy/toggle effects are not specified.

### 15. Missing from supplied source

**AMBIGUOUS — requires product decision/source file.** The brief requests 16 screens, but neither PDF contains an eighth page or another visible screen. Do not design this screen from assumptions.

### 16. Missing from supplied source

**AMBIGUOUS — requires product decision/source file.** See screen 15.

## 3. Navigation map

Only visually evidenced actions are mapped with confidence; arrows show an implied destination when a matching supplied screen exists.

| Screen | User action | Destination / confidence |
|---|---|---|
| 1 | Get Started | Screen 2 likely, **uncertain** (step 1 is absent) |
| 1 | Sign In | Not supplied — **AMBIGUOUS** |
| 2 | Continue to Job Sources | 3 |
| 2 | Replace | Resume selection/upload — not supplied |
| 3 | Continue | 4 likely, **uncertain** |
| 4 | Save Preferences | 5 likely, **uncertain** |
| 5 | Review & Apply Now | 7 likely (job details differ in copy) |
| 5 | View All / Jobs tab | 6 likely |
| 6 | View Job | 7 likely (list/card content differs) |
| 6 | Edit Preferences | 4 likely |
| 7 | Tailor Resume | 8 |
| 7 / 8 | Apply Now | External application flow — not supplied |
| 8 | Review Tailored Resume | 9 |
| 9 | Back | 8 likely |
| 10 | View Details | 11 likely (job/company data differ) |
| 11 | Track on Portal | External employer portal — not supplied |
| shared tabs | Home / Jobs / Applications / Profile; Optimize / Jobs / Alerts / Profile | Corresponding supplied root screen where present; labels differ across flows — **AMBIGUOUS** |
| 12 | alert CTAs | Matching job/resume/report destinations partly supplied; exact routes **uncertain** |
| 13 | gear | 14 likely |
| 14 | Profile/Edit | 13 likely; relation **uncertain** |

## 4. Design system

- **Color:** near-white/slightly blue-gray canvas; charcoal primary text; cool-medium gray metadata; vivid cornflower/royal blue primary (`~#4F8CE8` visually); darker royal blue on CTA/Optimize; green success/match accents; pale blue callouts/icon tiles; occasional purple and amber metric accents; deep navy top-match card. Exact hex values are **AMBIGUOUS — requires design tokens/source**.
- **Typography:** large high-contrast serif display headings on onboarding/main discovery screens; other titles use bold rounded sans; body is a readable gray sans; section labels/metrics are uppercase, small, bold with tracking; blue italic serif is an accent. Exact font families, sizes, and line heights are not recoverable from screenshots.
- **Spacing/layout:** regular 16–24 px horizontal gutters, 12–16 px card gaps, generous 20–32 px section separation; list rows about 56–72 px; fixed bottom tabs. Exact measurements are **AMBIGUOUS**.
- **Controls:** primary blue rounded rectangle buttons (roughly 12–16 px radius), secondary white outlined buttons, compact rounded chips, blue-on/off switches, selected outlined tiles, range sliders, search fields, radio cards, tabs with blue underline, circular floating action buttons.
- **Surfaces:** white/pale panels with thin neutral borders; rounded cards generally 12–16 px; subtle low-elevation shadows; dark navy promotional card; occasional blue-tinted information cards.
- **Icons/images:** thin outline system-style icons, blue icon tiles, job/company logos and decorative AI illustrations. Use a coherent icon set; source asset licensing and exact assets are **AMBIGUOUS**.

## 5. Reusable components

- `AppShell` with top/header variants and `PrimaryBottomNavigation` (parameterized label sets/active tab).
- `PrimaryButton`, `SecondaryOutlinedButton`, `IconButton`, `PillChip`, `TagChip`, `StatusBadge`, `ToggleRow`, `SegmentTabBar`, `SearchField`, `FilterButton`.
- `SectionHeader`, `SettingsRow`, `InfoCallout`, `MetricTile`, `EmptyOrTipCard`, `Progress/MatchScoreCard`, `RangeSliderCard`.
- `SelectablePlatformCard`, `SelectableOptionTile`, `ProviderOptionCard`, `ResumeSummaryCard`, `JobMatchCard`, `JobTagList`, `TimelineStep`, `NotificationCard`, `DocumentPreviewCard`.

## 6. Product functionality

### A. Visibly represented

Onboarding/sign-in entry; resume analyzed/verified state; source selection; preferences; search status and metrics; AI job-match scores/reasons; job browsing/search/filter/sort affordances; job detail, tailoring, export/download, apply affordances; application statuses/timeline/external tracking; alert feed; profile, AI-provider selection, and preferences/privacy controls.

### B. Future functionality not implemented

Resume upload/parsing; profile management; job-source selection and syncing; searching/filtering (salary, paid/unpaid, role, type); AI matching and resume tailoring; application links/tracking; notifications and background search; multi-platform integrations; provider integrations such as OpenAI, Gemini, and Claude; authentication, APIs, database, file export, and all persistence. Their contracts, privacy model, pricing/entitlements, and error/empty/loading states require product decisions.

## 7. Proposed architecture (not implemented)

- Use feature-first clean architecture: presentation (screens/widgets/state), domain (entities/use cases/repository interfaces), data (DTOs, sources, repository implementations), and app-level theme/router/DI.
- Start with presentation-only fixture repositories that implement domain interfaces; replace with remote/local sources only after API and privacy decisions are approved.
- Use immutable view models/entities for resume, preference, job, match, application, alert, provider, and settings; keep parsing/API DTOs in data only.
- Select one state-management approach before implementation. `flutter_riverpod` is a suitable future choice for scoped async state and testability; do not mix approaches.
- Use declarative named routes with typed route parameters; route external destinations behind an explicit launcher/service abstraction.
- Put exact visual values in `AppTheme`/design-token extensions and test core widget states with golden/widget tests after assets and target device sizes are agreed.

## 8. Proposed future `lib/` structure (do not create yet)

```text
lib/
  app/                 # app bootstrap, router, theme, dependency wiring
  core/
    constants/         # tokens, route names, strings where appropriate
    theme/
    widgets/           # truly shared UI primitives
    utils/
    services/          # e.g. external-link/file abstractions
  features/
    onboarding/{presentation,domain,data}/
    resume/{presentation,domain,data}/
    job_sources/{presentation,domain,data}/
    preferences/{presentation,domain,data}/
    home/{presentation,domain,data}/
    jobs/{presentation,domain,data}/
    applications/{presentation,domain,data}/
    notifications/{presentation,domain,data}/
    profile/{presentation,domain,data}/
    settings/{presentation,domain,data}/
  main.dart
```

## 9. Recommended future dependencies (do not install yet)

| Package | Purpose / why useful | Built-in replacement? |
|---|---|---|
| `go_router` | Declarative, nested, deep-link-capable app routing for tabs and detail pages. | Yes: `Navigator`/`Router`; use built-in for a small fixed flow. |
| `flutter_riverpod` | Testable dependency injection and async feature state without `BuildContext` coupling. | Yes: `setState`, `InheritedWidget`, `ChangeNotifier`; sufficient early on. |
| `freezed` + `json_serializable` + `build_runner` | Immutable models, unions for UI state, safe JSON mapping as APIs arrive. | Yes: manual model/JSON code; avoids generators/dependency cost. |
| `dio` | Configurable HTTP client, interceptors, cancellation, uploads. | Yes: `package:http` or `HttpClient`; built-ins are enough for modest APIs. |
| `flutter_secure_storage` | Secure device storage for approved auth tokens/secrets. | No equivalent secure cross-platform Flutter API; only introduce with auth. |
| `file_picker` | User resume selection across mobile/desktop targets. | Partly: platform channels; package is more practical. |
| `open_filex` / `url_launcher` | Open exported PDFs and explicitly launch application/portal links. | Partly: platform channels; packages simplify supported platforms. |
| `cached_network_image` | Caching/loading/error image states for remote logos/avatars. | Yes: `Image.network` with custom cache/state behavior. |
| `google_fonts` | Match an approved font if licensing/network bundling is resolved. | Yes: bundle licensed font assets or use system fonts. |

## 10. Recommended implementation order

1. Confirm the two missing design screens, canonical navigation/tab labels, assets, typography, and exact tokens.
2. Build design tokens/theme, app shell, header variants, and the two evidenced bottom-navigation variants (or unify only after a decision).
3. Build shared controls, cards, chips, settings rows, score/progress components, and fixture models.
4. Establish routes and static navigation for screens 1–14; preserve unsupported targets as disabled or explicitly stubbed only after approval.
5. Implement 1, then 2–4 onboarding/profile-setup screens.
6. Implement 5 Home, 6 Jobs list, 7 Job detail.
7. Implement 8 optimization result and 9 tailored-resume preview.
8. Implement 10 Applications and 11 Application Details timeline.
9. Implement 12 Notifications, 13 Account Profile, and 14 Settings.
10. Implement supplied screens 15–16 only after their source designs are provided.
11. Add screen-specific interactive behavior, loading/empty/error states, backend integrations, and tests only once contracts are approved.

## 11. Ambiguities/questions requiring product decision

1. The supplied PDFs show 14 pages, not the requested 16. Please provide the two missing screens or correct the expected count.
2. Is this one app with a single canonical product name and navigation? Screens 1–7 use `AI Job Hunter` and Home/Jobs/Applications/Profile; screens 8–14 use Optimize/Jobs/Alerts/Profile and screens 13–14 refer to Lumina AI.
3. Which bottom tab owns Applications (screen 10 visibly highlights Jobs), and what is the Settings versus Account Profile route relationship?
4. What is the complete onboarding sequence, authentication flow, and post-preferences destination?
5. Which elements are real assets, which may use system icons, and what licensed font family/token values should be used?
6. What are the exact semantics and sources for job-platform sync, filters, salary currency/ranges (₹ screen 4 vs $ screen 14), match scores, provider choices, and premium indicators?
7. Which external actions (apply, portal, export/download, resume edit) are in scope, and what permissions/privacy, error, loading, empty, accessibility, and responsive requirements apply?
